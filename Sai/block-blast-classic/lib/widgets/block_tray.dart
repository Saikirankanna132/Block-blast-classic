import 'package:flutter/material.dart';

import '../models/game_state.dart';
import 'block_preview.dart';

/// The tray of 3 draggable blocks at the bottom of the game screen.
class BlockTray extends StatelessWidget {
  const BlockTray({
    super.key,
    required this.state,
    this.highContrast = false,
    this.colorBlindMode = false,
  });

  final GameState state;
  final bool highContrast;
  final bool colorBlindMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < state.tray.length; i++)
            _TraySlot(
              index: i,
              state: state,
              highContrast: highContrast,
              colorBlindMode: colorBlindMode,
            ),
        ],
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.index,
    required this.state,
    required this.highContrast,
    required this.colorBlindMode,
  });

  final int index;
  final GameState state;
  final bool highContrast;
  final bool colorBlindMode;

  @override
  Widget build(BuildContext context) {
    final block = state.tray[index];

    // Fixed-size slot keeps the layout stable while dragging.
    return SizedBox(
      width: 110,
      height: 110,
      child: Center(
        child: block == null
            ? const SizedBox.shrink()
            : Draggable<BlockDragData>(
                data: BlockDragData(block: block, trayIndex: index),
                // The widget that follows the finger.
                feedback: Material(
                  color: Colors.transparent,
                  child: BlockPreview(
                    block: block,
                    cellSize: 30,
                    highContrast: highContrast,
                    colorBlindMode: colorBlindMode,
                  ),
                ),
                // What stays behind in the tray while dragging.
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: BlockPreview(
                    block: block,
                    highContrast: highContrast,
                    colorBlindMode: colorBlindMode,
                  ),
                ),
                child: BlockPreview(
                  block: block,
                  highContrast: highContrast,
                  colorBlindMode: colorBlindMode,
                ),
              ),
      ),
    );
  }
}
