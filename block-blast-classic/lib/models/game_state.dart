import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'block.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/haptics_service.dart';

/// Data carried by a drag gesture from the tray onto the board.
class BlockDragData {
  BlockDragData({required this.block, required this.trayIndex});
  final Block block;
  final int trayIndex;
}

/// The outcome of a successful placement, used for score popups,
/// particle effects, sounds and haptics.
class PlacementResult {
  PlacementResult({
    required this.points,
    required this.rowsCleared,
    required this.colsCleared,
    required this.clearedCells,
    required this.placedCells,
  });

  final int points;
  final int rowsCleared;
  final int colsCleared;

  /// Every board cell that was cleared, as [row, col] pairs.
  final List<List<int>> clearedCells;

  /// Every board cell the block now occupies, as [row, col] pairs.
  final List<List<int>> placedCells;

  int get linesCleared => rowsCleared + colsCleared;
}

/// Holds the whole game: board, tray, score, stats and drag-highlight state.
/// The UI listens to this with [AnimatedBuilder] / [ListenableBuilder].
class GameState extends ChangeNotifier {
  GameState({
    required this.storage,
    required this.sound,
    required this.haptics,
    BlockFactory? factory,
  }) : _factory = factory ?? BlockFactory();

  final StorageService storage;
  final SoundService sound;
  final HapticsService haptics;
  final BlockFactory _factory;

  /// 10x10 board. `null` = empty, otherwise an index into the block palette.
  late List<List<int?>> board;

  /// The three blocks at the bottom. A slot becomes null once its block
  /// is placed; a fresh set of three is dealt when all are used.
  List<Block?> tray = <Block?>[null, null, null];

  int score = 0;
  int best = 0;
  int rowsClearedTotal = 0;
  int colsClearedTotal = 0;
  int blocksPlaced = 0;
  bool gameOver = false;

  // ---- drag highlight state ----
  int? hoverRow;
  int? hoverCol;
  int? hoverTrayIndex;
  bool hoverValid = false;

  /// Fraction of board cells currently filled (0.0–1.0).
  double get boardFillRatio {
    var filled = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell != null) filled++;
      }
    }
    return filled / (GameConfig.boardSize * GameConfig.boardSize);
  }

  void newGame() {
    board = List.generate(
      GameConfig.boardSize,
      (_) => List<int?>.filled(GameConfig.boardSize, null),
    );
    score = 0;
    rowsClearedTotal = 0;
    colsClearedTotal = 0;
    blocksPlaced = 0;
    gameOver = false;
    best = storage.bestScore;
    clearHover();
    _dealTray();
    notifyListeners();
  }

  void _dealTray() {
    final fill = boardFillRatio;
    tray = List.generate(
      GameConfig.traySize,
      (_) => _factory.nextBlock(boardFillRatio: fill),
    );
    notifyListeners();
  }

  /// True when [block]'s top-left corner can sit at ([row], [col]).
  bool canPlace(Block block, int row, int col) {
    for (final cell in block.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      if (r < 0 ||
          r >= GameConfig.boardSize ||
          c < 0 ||
          c >= GameConfig.boardSize) {
        return false;
      }
      if (board[r][c] != null) return false;
    }
    return true;
  }

  /// True when [block] fits anywhere on the current board.
  bool canPlaceAnywhere(Block block) {
    for (var r = 0; r <= GameConfig.boardSize - block.height; r++) {
      for (var c = 0; c <= GameConfig.boardSize - block.width; c++) {
        if (canPlace(block, r, c)) return true;
      }
    }
    return false;
  }

  /// Converts the cell under the player's finger into a clamped top-left
  /// anchor so the block snaps neatly onto the grid.
  List<int> anchorFor(Block block, int row, int col) {
    var r = row - block.height ~/ 2;
    var c = col - block.width ~/ 2;
    r = r.clamp(0, GameConfig.boardSize - block.height);
    c = c.clamp(0, GameConfig.boardSize - block.width);
    return [r, c];
  }

  /// Places the tray block at ([row], [col]).
  /// Returns null when the placement is illegal.
  PlacementResult? place(int trayIndex, int row, int col) {
    final block = tray[trayIndex];
    if (block == null || gameOver) return null;
    if (!canPlace(block, row, col)) return null;

    final placedCells = <List<int>>[];
    for (final cell in block.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      board[r][c] = block.colorIndex;
      placedCells.add([r, c]);
    }
    tray[trayIndex] = null;
    blocksPlaced++;

    var points = block.cellCount * GameConfig.pointsPerSquare;

    // Find completely filled rows and columns.
    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var r = 0; r < GameConfig.boardSize; r++) {
      if (board[r].every((cell) => cell != null)) fullRows.add(r);
    }
    for (var c = 0; c < GameConfig.boardSize; c++) {
      var full = true;
      for (var r = 0; r < GameConfig.boardSize; r++) {
        if (board[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    // Clear them, collecting every cleared cell once (intersections count once).
    final clearedCells = <List<int>>[];
    bool alreadyCleared(int r, int c) =>
        clearedCells.any((p) => p[0] == r && p[1] == c);
    for (final r in fullRows) {
      for (var c = 0; c < GameConfig.boardSize; c++) {
        clearedCells.add([r, c]);
        board[r][c] = null;
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < GameConfig.boardSize; r++) {
        if (!alreadyCleared(r, c)) clearedCells.add([r, c]);
        board[r][c] = null;
      }
    }

    final lines = fullRows.length + fullCols.length;
    points += lines * GameConfig.pointsPerLine;
    if (lines > 1) {
      // Combo bonus for clearing several lines with one placement.
      points += (lines - 1) * GameConfig.comboBonusPerExtraLine;
    }

    rowsClearedTotal += fullRows.length;
    colsClearedTotal += fullCols.length;
    score += points;

    clearHover();

    if (tray.every((b) => b == null)) {
      _dealTray();
    }

    _checkGameOver();
    notifyListeners();

    // Feedback — fire and forget, never blocks the game.
    if (lines > 1) {
      haptics.celebrate();
    } else {
      haptics.tap();
    }
    if (lines > 0) {
      sound.playClear(lines);
    } else {
      sound.playPlace();
    }
    if (gameOver) {
      _finishGame();
    }

    return PlacementResult(
      points: points,
      rowsCleared: fullRows.length,
      colsCleared: fullCols.length,
      clearedCells: clearedCells,
      placedCells: placedCells,
    );
  }

  /// Called while a block hovers over the board so we can highlight
  /// the would-be placement footprint.
  void setHover({required int row, required int col, required int trayIndex}) {
    final block = tray[trayIndex];
    hoverRow = row;
    hoverCol = col;
    hoverTrayIndex = trayIndex;
    hoverValid = block != null && canPlace(block, row, col);
    notifyListeners();
  }

  void clearHover() {
    if (hoverRow == null && hoverTrayIndex == null) return;
    hoverRow = null;
    hoverCol = null;
    hoverTrayIndex = null;
    hoverValid = false;
    notifyListeners();
  }

  /// Game over when none of the remaining tray blocks fits anywhere.
  void _checkGameOver() {
    for (final block in tray) {
      if (block != null && canPlaceAnywhere(block)) return;
    }
    if (tray.every((b) => b == null)) return; // just dealt; not possible
    gameOver = true;
  }

  /// Persists stats + best score exactly once per finished game.
  Future<void> _finishGame() async {
    sound.playGameOver();
    final s = storage;
    s.gamesPlayed = s.gamesPlayed + 1;
    s.totalScore = s.totalScore + score;
    s.totalBlocksPlaced = s.totalBlocksPlaced + blocksPlaced;
    s.totalRowsCleared = s.totalRowsCleared + rowsClearedTotal;
    s.totalColsCleared = s.totalColsCleared + colsClearedTotal;
    if (score > s.bestScore) {
      s.bestScore = score;
      best = score;
    }
    notifyListeners();
  }
}
