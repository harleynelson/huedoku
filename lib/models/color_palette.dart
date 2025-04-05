// File: lib/models/color_palette.dart
// Location: ./lib/models/color_palette.dart

import 'package:flutter/material.dart';

// Represents a single palette available in the game
class ColorPalette {
  final String name;
  final List<Color> colors; // Should contain exactly 9 distinct colors

  // --- Removed 'const' from constructor ---
  ColorPalette({required this.name, required this.colors})
      // The assert still runs for non-const instances or during runtime checks
      : assert(colors.length == 9, 'Palette must contain exactly 9 colors.');

  // --- Changed 'static const' to 'static final' ---
  static final ColorPalette classic = ColorPalette(
    name: 'Classic',
    colors: [
      Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange,
      Colors.cyan, Colors.pink, Colors.brown,
    ],
  );

  static final ColorPalette forest = ColorPalette(
    name: 'Forest',
    colors: [
      const Color(0xFF556B2F), // DarkOliveGreen
      const Color(0xFF8FBC8F), // DarkSeaGreen
      const Color(0xFF228B22), // ForestGreen
      const Color(0xFF006400), // DarkGreen
      const Color(0xFF9ACD32), // YellowGreen
      const Color(0xFF6B8E23), // OliveDrab
      const Color(0xFFBDB76B), // DarkKhaki
      const Color(0xFFCD853F), // Peru
      const Color(0xFFA0522D), // Sienna
    ],
  );

  static final ColorPalette ocean = ColorPalette(
    name: 'Ocean',
    colors: [
      const Color(0xFF000080), // Navy
      const Color(0xFF1E90FF), // DodgerBlue
      const Color(0xFF00BFFF), // DeepSkyBlue
      const Color(0xFF87CEEB), // SkyBlue
      const Color(0xFF4682B4), // SteelBlue
      const Color(0xFFADD8E6), // LightBlue
      const Color(0xFFB0E0E6), // PowderBlue
      const Color(0xFFAFEEEE), // PaleTurquoise
      const Color(0xFF00CED1), // DarkTurquoise
    ],
  );

   // Colorblind Friendly Palette (Example using Paul Tol's vibrant scheme)
   // Ref: https://personal.sron.nl/~pault/
   static final ColorPalette accessibleVibrant = ColorPalette(
     name: 'Accessible Vibrant',
     colors: [
       const Color(0xFFEE7733), // orange
       const Color(0xFF0077BB), // blue
       const Color(0xFF33BBEE), // cyan
       const Color(0xFFEE3377), // magenta
       const Color(0xFFCC3311), // red
       const Color(0xFF009988), // teal
       const Color(0xFFBBBBBB), // grey
       const Color(0xFFDDAA33), // dark yellow / light brown
       const Color(0xFF99DDFF), // light blue
     ],
   );


  // This list now holds 'final' ColorPalette objects
  static List<ColorPalette> defaultPalettes = [
    classic,
    forest,
    ocean,
    accessibleVibrant,
    // Add more palettes here
  ];
}

// Represents how cell identifiers are displayed (on top of color)
enum CellOverlay { none, numbers, patterns }