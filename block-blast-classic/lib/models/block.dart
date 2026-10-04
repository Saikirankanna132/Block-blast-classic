import 'dart:math';

import '../utils/constants.dart';

/// An immutable puzzle block: a small grid of filled (1) / empty (0) cells
/// plus an index into [BlockPalette.colors].
class Block {
  Block({
    required this.shape,
    required this.colorIndex,
    String? id,
  })  : id = id ?? 'b${_counter++}',
        assert(shape.isNotEmpty &&
            shape.every((row) => row.length == shape[0].length));

  static int _counter = 0;

  final List<List<int>> shape;
  final int colorIndex;
  final String id;

  int get width => shape[0].length;
  int get height => shape.length;

  /// Number of filled squares — used for scoring (+10 per square).
  int get cellCount =>
      shape.expand((row) => row).where((cell) => cell == 1).length;

  /// All filled cell offsets as [row, col] pairs.
  List<List<int>> get cells {
    final out = <List<int>>[];
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if (shape[r][c] == 1) out.add([r, c]);
      }
    }
    return out;
  }

  /// A 90° clockwise rotated copy (handy for generating variants).
  Block rotated() {
    final rows = height;
    final cols = width;
    final next = List.generate(cols, (_) => List.filled(rows, 0));
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        next[c][rows - 1 - r] = shape[r][c];
      }
    }
    return Block(shape: next, colorIndex: colorIndex);
  }
}

/// A shape definition with its spawn weight. Shapes flagged [big] are
/// starved when the board gets crowded so the game stays fair.
class _ShapeDef {
  const _ShapeDef(this.matrix, this.weight, {this.big = false});
  final List<List<int>> matrix;
  final int weight;
  final bool big;
}

/// Generates random blocks. Large shapes become rarer as the board fills up,
/// which keeps the game relaxing instead of unfair.
class BlockFactory {
  BlockFactory({Random? random}) : _random = random ?? Random();

  final Random _random;

  // ignore: unused_field — kept as documentation of the full classic set.
  static const List<_ShapeDef> _shapes = [
    _ShapeDef([[1]], 10), // single
    _ShapeDef([[1, 1]], 10), // domino H
    _ShapeDef([[1], [1]], 10), // domino V
    _ShapeDef([[1, 1, 1]], 9), // 3-line H
    _ShapeDef([[1], [1], [1]], 9), // 3-line V
    _ShapeDef([[1, 1, 1, 1]], 7), // 4-line H
    _ShapeDef([[1], [1], [1], [1]], 7), // 4-line V
    _ShapeDef([[1, 1, 1, 1, 1]], 4, big: true), // 5-line H
    _ShapeDef([[1], [1], [1], [1], [1]], 4, big: true), // 5-line V
    _ShapeDef([[1, 1], [1, 1]], 9), // small square
    _ShapeDef([[1, 1, 1], [1, 1, 1], [1, 1, 1]], 3, big: true), // large square
    _ShapeDef([[1, 0], [1, 0], [1, 1]], 7), // L
    _ShapeDef([[0, 1], [0, 1], [1, 1]], 7), // reverse L (J)
    _ShapeDef([[1, 1, 1], [0, 1, 0]], 6), // T
    _ShapeDef([[0, 1, 0], [1, 1, 1]], 6), // T upside down
    _ShapeDef([[1, 1, 0], [0, 1, 1]], 5), // Z
    _ShapeDef([[0, 1, 1], [1, 1, 0]], 5), // reverse Z (S)
    _ShapeDef([[0, 1, 0], [1, 1, 1], [0, 1, 0]], 4, big: true), // plus
    _ShapeDef([[1, 1], [1, 0]], 8), // small corner
    _ShapeDef([[1, 1], [0, 1]], 8), // small corner mirrored
    _ShapeDef([[1, 1, 1], [1, 0, 0]], 5), // big corner
    _ShapeDef([[1, 1, 1], [0, 0, 1]], 5), // big corner mirrored
  ];

  /// Returns a random block, biased toward small shapes when [boardFillRatio]
  /// (0.0–1.0) is high so the player almost always has a playable move.
  Block nextBlock({required double boardFillRatio}) {
    var total = 0;
    final weights = <int>[];
    for (final def in _shapes) {
      var w = def.weight;
      if (def.big) {
        if (boardFillRatio > 0.55) {
          w = (w / 4).ceil(); // heavily starve big blocks late-game
        } else if (boardFillRatio > 0.35) {
          w = (w / 2).ceil();
        }
      }
      weights.add(w);
      total += w;
    }

    var roll = _random.nextInt(total);
    var index = 0;
    for (; index < weights.length; index++) {
      roll -= weights[index];
      if (roll < 0) break;
    }
    final def = _shapes[index.clamp(0, _shapes.length - 1)];
    return Block(
      shape: def.matrix.map((row) => List<int>.from(row)).toList(),
      colorIndex: _random.nextInt(BlockPalette.colors.length),
    );
  }
}
