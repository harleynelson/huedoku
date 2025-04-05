// File: lib/widgets/bokeh_painter.dart
// Location: ./lib/widgets/bokeh_painter.dart

import 'dart:math';
import 'dart:ui' as ui; // Import for ImageFilter
import 'package:flutter/material.dart';

// Represents a single bokeh particle
class BokehParticle {
  Offset position;
  double radius;
  Color color;
  // Add velocity or other properties for animation later if needed

  BokehParticle({required this.position, required this.radius, required this.color});
}

class BokehPainter extends CustomPainter {
  final List<BokehParticle> particles;
  final Random random = Random(); // Keep random for potential future animation

  BokehPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return; // Don't paint if no particles

    final Paint paint = Paint();

    // Apply a blur effect - adjust sigma for desired blurriness with smaller circles
    final Paint blurPaint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0); // Slightly less blur maybe

    // Using saveLayer/restoreLayer applies the blur to the group of circles
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), blurPaint);
    for (var particle in particles) {
      // Make circles semi-transparent - adjust opacity as needed
      paint.color = particle.color.withOpacity(0.55);
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
     canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BokehPainter oldDelegate) {
    // Repaint if the particle list object itself changes reference
    return oldDelegate.particles != particles;
  }
}

// --- Updated Helper function ---
List<BokehParticle> createBokehParticles(Size screenSize, bool isDarkMode, int count) {
  final Random random = Random();
  List<BokehParticle> particles = [];

  // Define complementary color sets based on the fixed gradients
   final List<Color> lightBokehPalette = [
      // Complements: Teal[100]!, LightBlue[200]!
      Colors.teal[50]!.withOpacity(0.7),
      Colors.lightBlue[50]!.withOpacity(0.7),
      Colors.greenAccent[100]!.withOpacity(0.6),
      Colors.cyan[100]!.withOpacity(0.6),
      Colors.white.withOpacity(0.3),
   ];

   final List<Color> darkBokehPalette = [
       // Complements: BlueGrey[800]!, Grey[900]!
       Colors.blueGrey[700]!.withOpacity(0.6),
       Colors.grey[800]!.withOpacity(0.6),
       Colors.purple[900]!.withOpacity(0.5), // Muted purple
       Colors.indigo[900]!.withOpacity(0.5),
       Colors.white.withOpacity(0.2),
   ];

   List<Color> selectedPalette = isDarkMode ? darkBokehPalette : lightBokehPalette;

  // --- Reduced Radius Calculation ---
  // Example: Radius between 2% and 6% of screen width
  final double minRadius = screenSize.width * 0.02;
  final double maxRadius = screenSize.width * 0.06;
  final double radiusRange = maxRadius - minRadius;

  if (selectedPalette.isEmpty) return []; // Avoid errors if palettes are empty

  for (int i = 0; i < count; i++) {
    particles.add(BokehParticle(
      position: Offset(
        // Allow particles to slightly bleed off-screen for better edge coverage
        random.nextDouble() * (screenSize.width + maxRadius*2) - maxRadius,
        random.nextDouble() * (screenSize.height + maxRadius*2) - maxRadius,
      ),
      // Calculate radius within the new range
      radius: random.nextDouble() * radiusRange + minRadius,
      color: selectedPalette[random.nextInt(selectedPalette.length)],
    ));
  }
  return particles;
}