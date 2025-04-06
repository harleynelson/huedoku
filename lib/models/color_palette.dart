// File: lib/models/color_palette.dart
// Location: ./lib/models/color_palette.dart

import 'package:flutter/material.dart';

// Represents a single palette available in the game
class ColorPalette {
  final String name;
  final List<Color> colors; // Should contain exactly 9 distinct colors

  ColorPalette({required this.name, required this.colors})
      : assert(colors.length == 9, 'Palette must contain exactly 9 colors.');

  // --- Existing Palettes ---
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

  // --- New Palettes ---
  static final ColorPalette sunset = ColorPalette(
    name: 'Sunset',
    colors: [
      const Color(0xFFFBE48E), // Light Yellow
      const Color(0xFFF8C37A), // Pale Orange
      const Color(0xFFF4A261), // Sandy Brown (Orange)
      const Color(0xFFE76F51), // Burnt Sienna (Red-Orange)
      const Color(0xFFD94A5C), // Darker Coral Red
      const Color(0xFFC03961), // Magenta/Rose
      const Color(0xFF9A3466), // Deep Purple/Red
      const Color(0xFF722F6C), // Dark Purple
      const Color(0xFF4A2A71), // Very Dark Purple/Blue
    ],
  );

  static final ColorPalette pastel = ColorPalette(
    name: 'Pastel',
    colors: [
      const Color(0xFFA8E6CF), // Mint Green
      const Color(0xFFDCEDC1), // Light Lime
      const Color(0xFFFFF9C4), // Pale Yellow
      const Color(0xFFFFE0B2), // Light Orange
      const Color(0xFFFFCCBC), // Light Coral
      const Color(0xFFF8BBD0), // Light Pink
      const Color(0xFFE1BEE7), // Light Lavender
      const Color(0xFFD1C4E9), // Light Purple/Blue
      const Color(0xFFBBDEFB), // Light Blue
    ],
  );

   static final ColorPalette monochrome = ColorPalette(
     name: 'Monochrome',
     // Shades of grey from light to dark
     colors: [
       const Color(0xFFFFFFFF), // White
       const Color(0xFFE0E0E0), // Grey 100
       const Color(0xFFBDBDBD), // Grey 200
       const Color(0xFF9E9E9E), // Grey 300
       const Color(0xFF757575), // Grey 400
       const Color(0xFF616161), // Grey 500
       const Color(0xFF424242), // Grey 600
       const Color(0xFF303030), // Grey 700
       const Color(0xFF212121), // Grey 800/Black
     ],
   );

   static final ColorPalette retro = ColorPalette(
     name: 'Retro',
     colors: [
        const Color(0xFFF9D423), // Yellow
        const Color(0xFFFF4E50), // Red/Orange
        const Color(0xFFFC913A), // Orange
        const Color(0xFF59CD90), // Green
        const Color(0xFF30A9DE), // Blue
        const Color(0xFF247BA0), // Darker Blue
        const Color(0xFF702470), // Purple
        const Color(0xFFE4446F), // Pink
        const Color(0xFF8D5A9B), // Mauve
     ],
   );


  // --- Updated defaultPalettes List ---
  static List<ColorPalette> defaultPalettes = [
    classic,
    sunset, // Added
    pastel, // Added
    forest,
    ocean,
    retro, // Added
    monochrome, // Added
    accessibleVibrant,
    // Add more palettes here
  ];
}

// Represents how cell identifiers are displayed (on top of color)
enum CellOverlay { none, numbers, patterns }