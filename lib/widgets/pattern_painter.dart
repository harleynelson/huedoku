// File: lib/widgets/pattern_painter.dart
// Location: ./lib/widgets/pattern_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class PatternPainter extends CustomPainter {
  final int patternIndex;
  final Color color;
  final double strokeWidthMultiplier;

   PatternPainter({
    required this.patternIndex,
    required this.color,
    this.strokeWidthMultiplier = 0.06, // Keep toned-down default
  });

   @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // --- Define Padding Factor ---
    const double paddingFactor = 0.2; // 20% padding on each side
    if (paddingFactor < 0 || paddingFactor >= 0.5) return; // Basic validation

    // Calculate effective drawing area dimensions and offset
    final double effectiveWidth = size.width * (1.0 - 2 * paddingFactor);
    final double effectiveHeight = size.height * (1.0 - 2 * paddingFactor);
    final double offsetX = size.width * paddingFactor;
    final double offsetY = size.height * paddingFactor;

    // Ensure effective dimensions are non-negative
    if (effectiveWidth <= 0 || effectiveHeight <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.55) // Keep toned-down opacity
      ..style = PaintingStyle.stroke
      // Base stroke width on the *smaller* effective dimension
      ..strokeWidth = max(1.0, min(effectiveWidth, effectiveHeight) * strokeWidthMultiplier);

    // --- Adjusted Calculations based on Effective Area ---
    final double width = effectiveWidth; // Use effective width for calculations
    final double height = effectiveHeight;
    final double centerX = offsetX + width / 2; // Center within the effective area
    final double centerY = offsetY + height / 2;
    final double radius = min(width, height) / 3.0; // Radius based on effective area
    final double spacingX = width / 4.0; // Spacing based on effective area
    final double spacingY = height / 4.0;
    const double spacingFactor = 1.3; // Keep increased spacing

    // --- Adjusted Clipping ---
    // Clip to the padded, effective drawing area
    final RRect clipRRect = RRect.fromRectAndRadius(
       Rect.fromLTWH(offsetX, offsetY, width, height), // Use offset and effective dimensions
       // Radius can be based on original size or effective size, let's use effective
       Radius.circular(max(0, width * 0.1)),
    );
    canvas.clipRRect(clipRRect);

    // --- Adjusted Pattern Drawing Logic (using offsetX, offsetY, and new coords) ---
    switch (patternIndex % 9) {
      case 0: // Horizontal Lines
        paint.style = PaintingStyle.stroke;
        for (double y = spacingY * spacingFactor; y < height; y += spacingY * spacingFactor) {
          // Draw lines within the effective area using offsets
          canvas.drawLine(Offset(offsetX, offsetY + y), Offset(offsetX + width, offsetY + y), paint);
        }
        break;

      case 1: // Vertical Lines
         paint.style = PaintingStyle.stroke;
        for (double x = spacingX * spacingFactor; x < width; x += spacingX * spacingFactor) {
           // Draw lines within the effective area using offsets
           canvas.drawLine(Offset(offsetX + x, offsetY), Offset(offsetX + x, offsetY + height), paint);
        }
        break;

      case 2: // Center dot
        paint.style = PaintingStyle.fill;
        double dotRadius = radius * 0.5;
        // Draw circle at the center of the effective area
        canvas.drawCircle(Offset(centerX, centerY), dotRadius, paint);
        break;

       case 3: // Diagonal Lines (\)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         // Adjust loop bounds and drawLine offsets
         for (double d = -height; d < width; d += spacingX * spacingFactor) {
           canvas.drawLine(Offset(offsetX + d, offsetY), Offset(offsetX + d + height, offsetY + height), paint);
         }
        break;

       case 4: // Diagonal Lines (/)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         // Adjust loop bounds and drawLine offsets
         for (double d = 0; d < width + height; d += spacingX * spacingFactor) {
           canvas.drawLine(Offset(offsetX + d, offsetY), Offset(offsetX + d - height, offsetY + height), paint);
         }
         break;

      case 5: // Checkerboard -> Outline
        paint.style = PaintingStyle.stroke;
        double cellW = width / 3.0;
        double cellH = height / 3.0;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            if ((i + j) % 2 == 0) {
              // Draw rect within the effective area using offsets
              canvas.drawRect(Rect.fromLTWH(offsetX + i * cellW, offsetY + j * cellH, cellW, cellH), paint);
            }
          }
        }
        break;

      case 6: // Concentric Circles
        paint.style = PaintingStyle.stroke;
        double maxRadius = radius * 1.2; // Radius based on effective area
        for (double r = maxRadius; r > 0; r -= maxRadius * 0.6) {
           if (r > paint.strokeWidth / 2) {
             // Draw circle at the center of the effective area
             canvas.drawCircle(Offset(centerX, centerY), r, paint);
           }
        }
        break;

       case 7: // Simple Grid (Crosshair)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         // Draw lines centered within the effective area using offsets
         canvas.drawLine(Offset(centerX, offsetY), Offset(centerX, offsetY + height), paint);
         canvas.drawLine(Offset(offsetX, centerY), Offset(offsetX + width, centerY), paint);
         break;

       case 8: // Center Cross (+)
          paint.style = PaintingStyle.stroke;
          paint.strokeCap = StrokeCap.round;
          // Draw lines centered within the effective area using offsets
          canvas.drawLine(Offset(centerX, offsetY + height * 0.15), Offset(centerX, offsetY + height * 0.85), paint);
          canvas.drawLine(Offset(offsetX + width * 0.15, centerY), Offset(offsetX + width * 0.85, centerY), paint);
         break;

      default: // Fallback: Draw outline circle centered in effective area
         paint.style = PaintingStyle.stroke;
         canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

 @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.patternIndex != patternIndex ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidthMultiplier != strokeWidthMultiplier;
  }
}