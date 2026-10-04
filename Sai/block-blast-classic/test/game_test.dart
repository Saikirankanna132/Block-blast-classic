import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:block_blast_classic/models/block.dart';
import 'package:block_blast_classic/models/game_state.dart';
import 'package:block_blast_classic/services/haptics_service.dart';
import 'package:block_blast_classic/services/sound_service.dart';
import 'package:block_blast_classic/services/storage_service.dart';
import 'package:block_blast_classic/utils/constants.dart';

/// SharedPreferences needs mock values under flutter_test.
Future<StorageService> _testStorage() async {
  SharedPreferences.setMockInitialValues({});
  return StorageService.init();
}

void main() {
  test('BlockFactory generates valid blocks', () {
    final factory = BlockFactory(random: Random(42));
    for (var i = 0; i < 50; i++) {
      final block = factory.nextBlock(boardFillRatio: 0.2);
      expect(block.cellCount, greaterThan(0));
      expect(block.width, lessThanOrEqualTo(GameConfig.boardSize));
      expect(block.height, lessThanOrEqualTo(GameConfig.boardSize));
    }
  });

  test('Placing a block fills cells and scores per square', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final storage = await _testStorage();
    final state = GameState(
      storage: storage,
      sound: SoundService(),
      haptics: HapticsService(),
      factory: BlockFactory(random: Random(1)),
    )..newGame();

    // Force a known single block into the tray.
    state.tray[0] = Block(shape: [
      [1]
    ], colorIndex: 0);
    final result = state.place(0, 0, 0);
    expect(result, isNotNull);
    expect(state.board[0][0], 0);
    expect(result!.points, GameConfig.pointsPerSquare);
    expect(state.score, GameConfig.pointsPerSquare);
  });

  test('Full row clears and awards line points', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final storage = await _testStorage();
    final state = GameState(
      storage: storage,
      sound: SoundService(),
      haptics: HapticsService(),
      factory: BlockFactory(random: Random(1)),
    )..newGame();

    // Fill the first row except the last cell, then drop a single block.
    for (var c = 0; c < GameConfig.boardSize - 1; c++) {
      state.board[0][c] = 1;
    }
    state.tray[0] = Block(shape: [
      [1]
    ], colorIndex: 2);
    final result =
        state.place(0, 0, GameConfig.boardSize - 1);
    expect(result, isNotNull);
    expect(result!.rowsCleared, 1);
    expect(result.points,
        GameConfig.pointsPerSquare + GameConfig.pointsPerLine);
    // Row is empty again after the clear.
    expect(state.board[0].every((c) => c == null), isTrue);
  });

  test('Game over triggers when nothing fits', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final storage = await _testStorage();
    final state = GameState(
      storage: storage,
      sound: SoundService(),
      haptics: HapticsService(),
      factory: BlockFactory(random: Random(1)),
    )..newGame();

    // Fill the whole board except one cell, tray holds a 2x2 square.
    for (var r = 0; r < GameConfig.boardSize; r++) {
      for (var c = 0; c < GameConfig.boardSize; c++) {
        state.board[r][c] = 0;
      }
    }
    state.board[0][0] = null;
    state.tray[0] = Block(shape: [
      [1, 1],
      [1, 1],
    ], colorIndex: 0);
    state.tray[1] = null;
    state.tray[2] = null;

    // Simulate the post-deal check by placing nothing: directly verify
    // canPlaceAnywhere reports false, which is what triggers game over.
    expect(state.canPlaceAnywhere(state.tray[0]!), isFalse);
  });
}
