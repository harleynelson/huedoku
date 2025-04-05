// File: lib/widgets/pattern_painter.dart
// Location: ./lib/widgets/pattern_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class PatternPainter extends CustomPainter {
  final int patternIndex;
  final Color color; // Still accept color, though we won't use it in debug
  final double strokeWidthMultiplier;

   @override
  void paint(Canvas canvas, Size size) {
    // --- RESTORED ACTUAL PAINT LOGIC ---
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.85) // Use the passed color with good opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, min(size.width, size.height) * strokeWidthMultiplier); // Ensure minimum stroke width

    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = min(width, height) / 3.0;

    // Define the clipping area
    final RRect clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(paint.strokeWidth / 2, paint.strokeWidth / 2, width - paint.strokeWidth, height - paint.strokeWidth),
      Radius.circular(max(0, width * 0.1)),
    );
    canvas.clipRRect(clipRRect);

    // Helper constants for spacing
    final double spacingX = width / 4.0;
    final double spacingY = height / 4.0;

    switch (patternIndex % 9) {
      case 0: // Horizontal Lines (Fill variant)
        paint.style = PaintingStyle.fill;
        for (double y = spacingY * 0.75; y < height; y += spacingY) {
          canvas.drawRect(Rect.fromLTWH(0, y, width, spacingY / 2), paint);
        }
        break;

      case 1: // Vertical Lines (Fill variant)
         paint.style = PaintingStyle.fill;
        for (double x = spacingX * 0.75; x < width; x += spacingX) {
          canvas.drawRect(Rect.fromLTWH(x, 0, spacingX / 2, height), paint);
        }
        break;

      case 2: // Dots / Polka
        paint.style = PaintingStyle.fill;
        double dotRadius = radius / 3.0;
        for (int i = 0; i < 3; i++) {
           for (int j = 0; j < 3; j++) {
             canvas.drawCircle(Offset(centerX + (i-1)*spacingX*1.2, centerY + (j-1)*spacingY*1.2), dotRadius, paint);
           }
        }
        break;

       case 3: // Diagonal Lines (\)
         paint.strokeCap = StrokeCap.round;
         for (double d = -height; d < width; d += spacingX * 0.8) {
           canvas.drawLine(Offset(d, 0), Offset(d + height, height), paint);
         }
        break;

       case 4: // Diagonal Lines (/)
         paint.strokeCap = StrokeCap.round;
         for (double d = 0; d < width + height; d += spacingX * 0.8) {
           canvas.drawLine(Offset(d, 0), Offset(d - height, height), paint);
         }
         break;

      case 5: // Checkerboard
        paint.style = PaintingStyle.fill;
        double cellW = width / 3.0;
        double cellH = height / 3.0;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            if ((i + j) % 2 == 0) {
              canvas.drawRect(Rect.fromLTWH(i * cellW, j * cellH, cellW, cellH), paint);
            }
          }
        }
        break;

      case 6: // Concentric Circles
        double maxRadius = radius * 1.2;
        for (double r = maxRadius; r > 0; r -= maxRadius * 0.45) {
           if (r > paint.strokeWidth / 2) {
             canvas.drawCircle(Offset(centerX, centerY), r, paint);
           }
        }
        break;

       case 7: // Simple Grid (Crosshair)
         paint.strokeCap = StrokeCap.round;
         canvas.drawLine(Offset(centerX, 0), Offset(centerX, height), paint); // Vertical center
         canvas.drawLine(Offset(0, centerY), Offset(width, centerY), paint); // Horizontal center
         break;

       case 8: // Center Cross (+)
          paint.strokeCap = StrokeCap.round;
          paint.strokeWidth = max(1.5, min(size.width, size.height) * strokeWidthMultiplier * 1.5);
          canvas.drawLine(Offset(centerX, height * 0.15), Offset(centerX, height * 0.85), paint);
          canvas.drawLine(Offset(width * 0.15, centerY), Offset(width * 0.85, centerY), paint);
         break;

      default: // Fallback: Draw a simple circle
         canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
    // --- END RESTORED LOGIC ---
  }

// Constructor and shouldRepaint remain the same as the refined version
 PatternPainter({
    required this.patternIndex,
    required this.color,
    this.strokeWidthMultiplier = 0.1, // Default from previous refinement
  });

 @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.patternIndex != patternIndex ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidthMultiplier != strokeWidthMultiplier;
  }
  }