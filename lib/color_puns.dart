// File: lib/color_puns.dart
// Location: ./lib/color_puns.dart

import 'dart:math';

const List<String> colorPuns = [
  // Red
  "Red-iculous Skills!",
  "Red Hot!",
  "Red-y For More?",
  "Simply Red-markable",

  // Blue
  "Beyond Blue-lief!",
  "Blue-tiful Work!",
  "Out of the Blue!",

  // Green
  "Green Machine!",
  "Green Light Go!",
  "Ever-green Skills",
  "Mean Green Solving Machine",

  // Yellow
  "You're Golden!",

  // Purple
  "Purple Reign",
  "Grape Job!",

  // Orange
  "Orange You Clever!",

  // Pink
  "Tickled Pink",

  // Mixed Colors
  "Color Me Impressed",
  "Hue're Great!",
  "Chromatic Champion",
  "Palette Perfection!",
  "Dye-namic Finish",
  "Splash of Genius",
  "Rainbow Warrior",
  "Tone-tally Amazing",
  "Shade Runner",

  // Extras
  "On the Right Wavelength!",
  "Peak Pigment Power!",
  "Showed Your True Colors!",
  "Saturated with Success!",
  "Un-blue-lievable!",
];

// Helper function to get a random pun
String getRandomColorPun() {
  if (colorPuns.isEmpty) {
    return "Puzzle Solved!"; // Fallback
  }
  final random = Random();
  return colorPuns[random.nextInt(colorPuns.length)];
}