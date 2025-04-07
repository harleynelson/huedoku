// File: lib/widgets/bokeh_painter.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class BokehParticle {
  Offset position;
  double radius;
  Color color;
  Offset velocity;
  double initialOpacity;

  BokehParticle({
    required this.position,
    required this.radius,
    required this.color,
    required this.velocity,
    required this.initialOpacity,
  });

  void update(double animationValue, Size bounds) {
      position += velocity * animationValue;
      if (position.dx < -radius * 2) position = Offset(bounds.width + radius, position.dy);
      if (position.dx > bounds.width + radius * 2) position = Offset(-radius, position.dy);
      if (position.dy < -radius * 2) position = Offset(position.dx, bounds.height + radius);
      if (position.dy > bounds.height + radius * 2) position = Offset(position.dx, -radius);
  }
}

class BokehPainter extends CustomPainter {
  final List<BokehParticle> particles;
  final Animation<double>? animation;

  BokehPainter({required this.particles, this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    final Paint paint = Paint();
    final double currentAnimationValue = animation?.value ?? kMaxOpacity; // Use constant

    final Paint blurPaint = Paint()
      // --- UPDATED: Use constant for blur ---
      ..imageFilter = ui.ImageFilter.blur(sigmaX: kBokehBlurSigma, sigmaY: kBokehBlurSigma);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), blurPaint);

    for (var particle in particles) {
        // --- UPDATED: Use constant for radius factor ---
        double maxAssumedRadius = size.width * kBokehMaxRadiusFactor;
        // --- UPDATED: Use constants for opacity clamps ---
        double normalizedRadius = (particle.radius / maxAssumedRadius).clamp(kLowOpacity, kMaxOpacity);

        double pulse = (sin(currentAnimationValue * 2 * pi) + 1) / 2;
        // --- UPDATED: Use constants for lerp bounds ---
        double pulsingOpacity = lerpDouble(0.6, kMaxOpacity, pulse)!; // Keep 0.6 specific or make constant

        // --- UPDATED: Use constants for opacity clamps ---
        double finalOpacity = (particle.initialOpacity * normalizedRadius * pulsingOpacity).clamp(kLowOpacity, kHighOpacity);

        paint.color = particle.color.withOpacity(finalOpacity);
        canvas.drawCircle(particle.position, particle.radius, paint);
    }
     canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BokehPainter oldDelegate) {
    return oldDelegate.particles != particles || animation != null;
  }
}

// --- Updated Helper function (Uses constants) ---
List<BokehParticle> createBokehParticles(
    Size screenSize,
    bool isDarkMode,
    int count, // Count is passed in, often from a constant
    ColorPalette currentPalette,
  ) {
  final Random random = Random();
  List<BokehParticle> particles = [];

  List<Color> bokehPalette = currentPalette.colors.map((c) {
      HSLColor hsl = HSLColor.fromColor(c);
      double lightness = isDarkMode
          ? (hsl.lightness * 0.6).clamp(0.1, 0.4) // Keep specific or make constants
          : (hsl.lightness * 1.2).clamp(0.6, 0.9); // Keep specific or make constants
      double saturation = (hsl.saturation * 0.5).clamp(0.2, 0.6); // Keep specific or make constants
      return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }).toList();

   // --- UPDATED: Use constants for opacity ---
  bokehPalette.addAll(isDarkMode
      ? [Colors.blueGrey[800]!.withOpacity(kMediumOpacity), Colors.white.withOpacity(kLowOpacity)]
      : [Colors.teal[50]!.withOpacity(kMediumOpacity), Colors.white.withOpacity(kLowMediumOpacity)]);

  if (bokehPalette.isEmpty || screenSize.isEmpty) return [];

  // --- UPDATED: Use constants for radius factors ---
  final double minRadius = screenSize.width * kBokehMinRadiusFactor;
  final double maxRadius = screenSize.width * kBokehMaxRadiusFactor;
  final double radiusRange = maxRadius - minRadius;

  // --- UPDATED: Use constant for velocity ---
  final double maxVelocity = kBokehMaxVelocity;

  for (int i = 0; i < count; i++) {
      double radius = random.nextDouble() * radiusRange + minRadius;
      // --- UPDATED: Use constants for opacity range/clamp ---
      double initialOpacity = (random.nextDouble() * kMediumOpacity + 0.4).clamp(kMediumOpacity, kMediumHighOpacity); // Adjust 0.4 if needed

      particles.add(BokehParticle(
        position: Offset(
          random.nextDouble() * (screenSize.width + maxRadius*2) - maxRadius,
          random.nextDouble() * (screenSize.height + maxRadius*2) - maxRadius,
        ),
        radius: radius,
        color: bokehPalette[random.nextInt(bokehPalette.length)],
        velocity: Offset(
           (random.nextDouble() - 0.5) * 2 * maxVelocity,
           (random.nextDouble() - 0.5) * 2 * maxVelocity,
        ),
        initialOpacity: initialOpacity,
      ));
  }
  return particles;
}

// Helper function to linearly interpolate between two values. (Unchanged)
double? lerpDouble(num? a, num? b, double t) {
  if (a == null || b == null) {
    return null;
  }
  return a + (b - a) * t;
}