// Central place for compile-time constants: board size, scoring, colours.
import 'package:flutter/material.dart';

/// Board is always 10x10 as per the game spec.
class GameConfig {
  static const int boardSize = 10;
  static const int traySize = 3;

  // Scoring
  static const int pointsPerSquare = 10;
  static const int pointsPerLine = 100;

  // Combo bonus: clearing more than one line at once.
  static const int comboBonusPerExtraLine = 50;
}

/// Family-friendly block palette (also used by the color-blind mode
/// with patterns/labels on top of colour).
class BlockPalette {
  static const List<Color> colors = [
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFF97316), // orange
    Color(0xFFA855F7), // purple
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
    Color(0xFFEAB308), // yellow
  ];

  /// High-contrast alternatives for accessibility mode.
  static const List<Color> highContrastColors = [
    Color(0xFF0033CC),
    Color(0xFF007700),
    Color(0xFFCC5500),
    Color(0xFF6600CC),
    Color(0xFFCC0000),
    Color(0xFF007788),
    Color(0xFF997700),
  ];
}

/// Light / dark board backgrounds.
class BoardTheme {
  static const Color lightCell = Color(0xFFFFFBEB); // soft cream
  static const Color lightCellBorder = Color(0xFFE7E0CF);
  static const Color lightBoardBg = Color(0xFFFFFDF5);

  static const Color darkCell = Color(0xFF1F2937);
  static const Color darkCellBorder = Color(0xFF374151);
  static const Color darkBoardBg = Color(0xFF111827);
}
