import 'package:flutter/material.dart';

import '../models/block.dart';
import '../utils/constants.dart';

/// Renders a [Block] as a mini grid of rounded squares.
/// Used in the tray, as the drag feedback, and in previews.
class BlockPreview extends StatelessWidget {
  const BlockPreview({
    super.key,
    required this.block,
    this.cellSize = 26,
    this.highContrast = false,
    this.colorBlindMode = false,
  });

  final Block block;
  final double cellSize;
  final bool highContrast;
  final bool colorBlindMode;

  Color _color(BuildContext context) {
    final palette =
        highContrast ? BlockPalette.highContrastColors : BlockPalette.colors;
    var color = palette[block.colorIndex % palette.length];
    if (colorBlindMode) {
      // Slightly desaturate + darken so shapes stay distinguishable
      // without relying on hue alone; each shape also gets a label dot.
      color = Color.lerp(color, Colors.black, 0.08)!;
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < block.height; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < block.width; c++)
                Container(
                  width: cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(1.5),
                  decoration: block.shape[r][c] == 1
                      ? BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(cellSize * 0.22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        )
                      : null,
                  // In color-blind mode every filled square gets a small
                  // white dot so blocks are identifiable by pattern too.
                  child: block.shape[r][c] == 1 && colorBlindMode
                      ? Center(
                          child: Container(
                            width: cellSize * 0.28,
                            height: cellSize * 0.28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
      ],
    );
  }
}
