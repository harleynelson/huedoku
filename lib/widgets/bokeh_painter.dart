// File: lib/widgets/bokeh_painter.dart
// Location: ./lib/widgets/bokeh_painter.dart

import 'dart:math';
import 'dart:ui' as ui; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart'; // Import palette for harmony

// Represents a single bokeh particle with animation properties
class BokehParticle {
  Offset position;
  double radius;
  Color color;
  Offset velocity; // For animation drift
  double initialOpacity; // Base opacity

  BokehParticle({
    required this.position,
    required this.radius,
    required this.color,
    required this.velocity,
    required this.initialOpacity,
  });

  // Method to update particle position based on animation value and bounds
  void update(double animationValue, Size bounds) {
      // Simple linear movement - can be made more complex (e.g., sine wave)
      position += velocity * animationValue;

      // Wrap particles around the screen edges
      if (position.dx < -radius * 2) position = Offset(bounds.width + radius, position.dy);
      if (position.dx > bounds.width + radius * 2) position = Offset(-radius, position.dy);
      if (position.dy < -radius * 2) position = Offset(position.dx, bounds.height + radius);
      if (position.dy > bounds.height + radius * 2) position = Offset(position.dx, -radius);
  }
}

class BokehPainter extends CustomPainter {
  final List<BokehParticle> particles;
  final Animation<double>? animation; // Make animation nullable

  // Constructor now accepts optional animation
  BokehPainter({required this.particles, this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return; // Don't paint if no particles

    final Paint paint = Paint();
    final double currentAnimationValue = animation?.value ?? 1.0; // Use 1.0 if no animation

    // Optional: Apply a base blur to the layer - less blur for sharper small circles
    final Paint blurPaint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0); // Adjust blur

    // Using saveLayer/restoreLayer applies the blur to the group of circles
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), blurPaint);

    for (var particle in particles) {
        // --- Particle Update for Animation ---
        // Update particle position (optional, if animation drives position)
        // Note: If animation drives position, particles should be managed by the stateful widget
        // For simplicity here, we'll assume animation drives opacity pulsing or similar
        // particle.update(currentAnimationValue, size); // Uncomment if particles move

        // --- Depth Simulation (Opacity based on size) ---
        // Normalize radius (0 to 1) based on a typical max radius assumption (e.g., 10% of width)
        double maxAssumedRadius = size.width * 0.10;
        double normalizedRadius = (particle.radius / maxAssumedRadius).clamp(0.1, 1.0); // Clamp to avoid zero/extreme opacity

        // --- Opacity (Combine base opacity, depth, and pulsing) ---
         // Pulsing effect using sine wave based on animation value
        double pulse = (sin(currentAnimationValue * 2 * pi) + 1) / 2; // Ranges 0 to 1
        double pulsingOpacity = lerpDouble(0.6, 1.0, pulse)!; // Pulse between 60% and 100% of base

        // Combine effects: Base opacity * Depth Factor * Pulse Factor
        double finalOpacity = (particle.initialOpacity * normalizedRadius * pulsingOpacity).clamp(0.1, 0.8); // Clamp final opacity

        paint.color = particle.color.withOpacity(finalOpacity);

        // Draw the particle
        canvas.drawCircle(particle.position, particle.radius, paint);
    }
     canvas.restore(); // Apply the blur
  }

  @override
  bool shouldRepaint(covariant BokehPainter oldDelegate) {
    // Repaint if particles list changes OR if animation is running
    return oldDelegate.particles != particles || animation != null;
  }
}

// --- Updated Helper function ---
// Now accepts the current game palette for color harmony
List<BokehParticle> createBokehParticles(
    Size screenSize,
    bool isDarkMode,
    int count,
    ColorPalette currentPalette, // Added palette parameter
  ) {
  final Random random = Random();
  List<BokehParticle> particles = [];

  // --- Color Harmony ---
  // Generate bokeh colors based on the provided game palette
  List<Color> bokehPalette = currentPalette.colors.map((c) {
      // Generate lighter/darker variations or complementary colors
      // Example: Create slightly lighter/desaturated versions
      HSLColor hsl = HSLColor.fromColor(c);
       // Adjust lightness and saturation for bokeh effect
      double lightness = isDarkMode
          ? (hsl.lightness * 0.6).clamp(0.1, 0.4) // Darker, less saturated for dark mode
          : (hsl.lightness * 1.2).clamp(0.6, 0.9); // Lighter for light mode
      double saturation = (hsl.saturation * 0.5).clamp(0.2, 0.6); // Desaturate

      return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }).toList();

   // Add some neutral base colors depending on theme
  bokehPalette.addAll(isDarkMode
      ? [Colors.blueGrey[800]!.withOpacity(0.3), Colors.white.withOpacity(0.1)]
      : [Colors.teal[50]!.withOpacity(0.3), Colors.white.withOpacity(0.2)]);

  if (bokehPalette.isEmpty || screenSize.isEmpty) return []; // Avoid errors

  // --- Depth (Size Variation) ---
  // Increase range for more dramatic size differences
  final double minRadius = screenSize.width * 0.015; // Smaller minimum
  final double maxRadius = screenSize.width * 0.10; // Larger maximum
  final double radiusRange = maxRadius - minRadius;

  // --- Animation Properties ---
  final double maxVelocity = 0.5; // Max speed for drift


  for (int i = 0; i < count; i++) {
      double radius = random.nextDouble() * radiusRange + minRadius;
      // Base opacity - slightly varied
      double initialOpacity = (random.nextDouble() * 0.3 + 0.4).clamp(0.3, 0.7); // Base opacity 40-70%

      particles.add(BokehParticle(
        position: Offset(
          // Allow particles to slightly bleed off-screen for better edge coverage
          random.nextDouble() * (screenSize.width + maxRadius*2) - maxRadius,
          random.nextDouble() * (screenSize.height + maxRadius*2) - maxRadius,
        ),
        radius: radius,
        color: bokehPalette[random.nextInt(bokehPalette.length)],
        // Assign random velocity for drift animation
        velocity: Offset(
           (random.nextDouble() - 0.5) * 2 * maxVelocity, // Random X velocity (-max to +max)
           (random.nextDouble() - 0.5) * 2 * maxVelocity, // Random Y velocity (-max to +max)
        ),
        initialOpacity: initialOpacity,
      ));
  }
  return particles;
}

// Helper function to linearly interpolate between two values. Included for completeness.
double? lerpDouble(num? a, num? b, double t) {
  if (a == null || b == null) {
    return null;
  }
  return a + (b - a) * t;
}