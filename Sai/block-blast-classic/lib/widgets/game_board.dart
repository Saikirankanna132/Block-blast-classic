import 'package:flutter/material.dart';

import '../models/block.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import 'block_preview.dart';

/// The 10x10 board. Every cell is a [DragTarget] so blocks can be dropped
/// anywhere; while hovering we highlight the would-be footprint.
class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.state,
    required this.onPlaced,
    this.flashCells = const {},
    this.flashValue = 0.0,
    this.palette = BlockPalette.colors,
  });

  final GameState state;

  /// Called after a successful drop with the placement result and anchor.
  final void Function(PlacementResult result) onPlaced;

  /// Cells currently flashing (just-cleared), as "row,col" keys.
  final Set<String> flashCells;

  /// 1.0 → just cleared, 0.0 → flash finished.
  final double flashValue;

  /// Which colour palette to paint filled cells with.
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;
    final cellBg =
        dark ? BoardTheme.darkCell : BoardTheme.lightCell;
    final cellBorder =
        dark ? BoardTheme.darkCellBorder : BoardTheme.lightCellBorder;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: dark ? BoardTheme.darkBoardBg : BoardTheme.lightBoardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: GameConfig.boardSize,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: GameConfig.boardSize * GameConfig.boardSize,
          itemBuilder: (context, index) {
            final row = index ~/ GameConfig.boardSize;
            final col = index % GameConfig.boardSize;
            return DragTarget<BlockDragData>(
              onWillAcceptWithDetails: (details) {
                final anchor = state.anchorFor(
                    details.data.block, row, col);
                state.setHover(
                  row: anchor[0],
                  col: anchor[1],
                  trayIndex: details.data.trayIndex,
                );
                return true; // accept; validity is shown via highlight
              },
              onLeave: (_) => state.clearHover(),
              onAcceptWithDetails: (details) {
                final anchor = state.anchorFor(
                    details.data.block, row, col);
                final result = state.place(
                    details.data.trayIndex, anchor[0], anchor[1]);
                if (result != null) onPlaced(result);
              },
              builder: (context, candidate, rejected) {
                return _BoardCell(
                  row: row,
                  col: col,
                  state: state,
                  cellBg: cellBg,
                  cellBorder: cellBorder,
                  flashCells: flashCells,
                  flashValue: flashValue,
                  palette: palette,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.row,
    required this.col,
    required this.state,
    required this.cellBg,
    required this.cellBorder,
    required this.flashCells,
    required this.flashValue,
    required this.palette,
  });

  final int row;
  final int col;
  final GameState state;
  final Color cellBg;
  final Color cellBorder;
  final Set<String> flashCells;
  final double flashValue;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final filled = state.board[row][col];
    final key = '$row,$col';

    // Is this cell inside the hovered block's footprint?
    Color? highlight;
    if (state.hoverRow != null &&
        state.hoverTrayIndex != null &&
        state.tray[state.hoverTrayIndex!] != null) {
      final block = state.tray[state.hoverTrayIndex!]!;
      final hr = state.hoverRow!;
      final hc = state.hoverCol!;
      final lr = row - hr;
      final lc = col - hc;
      if (lr >= 0 &&
          lr < block.height &&
          lc >= 0 &&
          lc < block.width &&
          block.shape[lr][lc] == 1) {
        highlight = state.hoverValid
            ? Colors.green.withValues(alpha: 0.45)
            : Colors.red.withValues(alpha: 0.35);
      }
    }

    Widget cell;
    if (filled != null) {
      cell = Container(
        decoration: BoxDecoration(
          color: palette[filled % palette.length],
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      );
    } else {
      cell = Container(
        decoration: BoxDecoration(
          color: highlight ?? cellBg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: cellBorder, width: 1),
        ),
      );
    }

    // White flash overlay on just-cleared cells (explosion feel).
    if (flashCells.contains(key) && flashValue > 0) {
      cell = Stack(
        children: [
          cell,
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: flashValue * 0.9),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      );
    }
    return cell;
  }
}

/// Small helper to render a single block square at board scale.
/// (Kept for potential reuse in tutorials / previews.)
class BoardBlockCell extends StatelessWidget {
  const BoardBlockCell({super.key, required this.block});
  final Block block;

  @override
  Widget build(BuildContext context) => BlockPreview(block: block, cellSize: 20);
}
