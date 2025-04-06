// File: lib/models/color_palette.dart
// Location: ./lib/models/color_palette.dart

import 'package:flutter/material.dart';

// Represents a single palette available in the game
class ColorPalette {
  final String name;
  final List<Color> colors; // Should contain exactly 9 distinct colors

  // Use final instead of const for constructor if colors aren't always const
  ColorPalette({required this.name, required this.colors})
      : assert(colors.length == 9, 'Palette must contain exactly 9 colors.');

  // Use static final for palettes since Color() isn't always const
  static final ColorPalette classic = ColorPalette(
    name: 'Classic',
    colors: [
      Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange, // Standard Material - usually distinct enough
      Colors.cyan, Colors.pink, Colors.brown,
    ],
  );

  static final ColorPalette forest = ColorPalette(
    name: 'Forest',
    colors: [
      const Color(0xFF556B2F), const Color(0xFF8FBC8F), const Color(0xFF228B22),
      const Color(0xFF006400), const Color(0xFF9ACD32), const Color(0xFF6B8E23),
      const Color(0xFFBDB76B), const Color(0xFFCD853F), const Color(0xFFA0522D),
    ],
  );

  static final ColorPalette ocean = ColorPalette(
    name: 'Ocean',
    colors: [
      const Color(0xFF000080), const Color(0xFF1E90FF), const Color(0xFF00BFFF),
      const Color(0xFF87CEEB), const Color(0xFF4682B4), const Color(0xFFADD8E6),
      const Color(0xFFB0E0E6), const Color(0xFFAFEEEE), const Color(0xFF00CED1),
    ],
  );

   static final ColorPalette accessibleVibrant = ColorPalette(
     name: 'Accessible Vibrant',
     colors: [ // Seems distinct already
       const Color(0xFFEE7733), const Color(0xFF0077BB), const Color(0xFF33BBEE),
       const Color(0xFFEE3377), const Color(0xFFCC3311), const Color(0xFF009988),
       const Color(0xFFBBBBBB), const Color(0xFFDDAA33), const Color(0xFF99DDFF),
     ],
   );

  // --- Added/Adjusted Palettes ---
  static final ColorPalette sunset = ColorPalette(
    name: 'Sunset',
    colors: [
      const Color(0xFFFBE48E), // Light Yellow
      const Color(0xFFF8C37A), // Pale Orange
      const Color(0xFFF4A261), // Sandy Brown (Orange)
      const Color(0xFFE76F51), // Burnt Sienna (Red-Orange)
      const Color(0xFFD14058), // ADJUSTED: Darker/Redder Coral
      const Color(0xFFB03060), // ADJUSTED: More Purple Magenta/Rose
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
      const Color(0xFFFFDAB9), // ADJUSTED: More Peach, Less Pink Coral (PeachPuff)
      const Color(0xFFF4C2D7), // ADJUSTED: Cooler/Orchid Pink
      const Color(0xFFE1BEE7), // Light Lavender
      const Color(0xFFD1C4E9), // Light Purple/Blue
      const Color(0xFFBBDEFB), // Light Blue
    ],
  );

   static final ColorPalette monochrome = ColorPalette(
     name: 'Monochrome',
     colors: [ // No oranges/pinks
       const Color(0xFFFFFFFF), const Color(0xFFE0E0E0), const Color(0xFFBDBDBD),
       const Color(0xFF9E9E9E), const Color(0xFF757575), const Color(0xFF616161),
       const Color(0xFF424242), const Color(0xFF303030), const Color(0xFF212121),
     ],
   );

   static final ColorPalette retro = ColorPalette(
     name: 'Retro',
     colors: [
        const Color(0xFFF9D423), // Yellow
        const Color(0xFFF73C40), // ADJUSTED: More Red/Less Orange
        const Color(0xFFFC913A), // Orange
        const Color(0xFF59CD90), // Green
        const Color(0xFF30A9DE), // Blue
        const Color(0xFF247BA0), // Darker Blue
        const Color(0xFF702470), // Purple
        const Color(0xFFE03A7F), // ADJUSTED: More Magenta/Less Red Pink
        const Color(0xFF8D5A9B), // Mauve
     ],
   );
   // --- End Added/Adjusted Palettes ---

  // This list now holds 'final' ColorPalette objects
  // --- Updated List to Include New Palettes ---
  static final List<ColorPalette> defaultPalettes = [
    classic,
    retro, // Moved up as requested default previously
    sunset,
    pastel,
    forest,
    ocean,
    monochrome,
    accessibleVibrant,
    // Add more palettes here
  ];
  // --- End Updated List ---
}

// Represents how cell identifiers are displayed (on top of color)
enum CellOverlay { none, numbers, patterns }