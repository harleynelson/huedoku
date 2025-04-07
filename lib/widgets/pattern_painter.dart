// File: lib/widgets/pattern_painter.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'dart:math';
import 'package:flutter/material.dart';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class PatternPainter extends CustomPainter {
  final int patternIndex;
  final Color color;
  final double strokeWidthMultiplier;

   PatternPainter({
    required this.patternIndex,
    required this.color,
    // --- UPDATED: Use constant for default multiplier ---
    this.strokeWidthMultiplier = kPatternStrokeMultiplier,
  });

   @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // --- UPDATED: Use constant for padding factor ---
    const double paddingFactor = kPatternPaddingFactor;
    if (paddingFactor < 0 || paddingFactor >= 0.5) return;

    final double effectiveWidth = size.width * (1.0 - 2 * paddingFactor);
    final double effectiveHeight = size.height * (1.0 - 2 * paddingFactor);
    final double offsetX = size.width * paddingFactor;
    final double offsetY = size.height * paddingFactor;

    if (effectiveWidth <= 0 || effectiveHeight <= 0) return;

    final paint = Paint()
      // --- UPDATED: Use constant for opacity ---
      ..color = color.withOpacity(0.55) // Keep specific or make constant
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(kDefaultBorderWidth, min(effectiveWidth, effectiveHeight) * strokeWidthMultiplier); // Use constant min width

    final double width = effectiveWidth;
    final double height = effectiveHeight;
    final double centerX = offsetX + width / 2;
    final double centerY = offsetY + height / 2;
    // --- UPDATED: Use kBoxSize constant ---
    final double radius = min(width, height) / kBoxSize;
    final double spacingX = width / 4.0; // Keep specific or make constant
    final double spacingY = height / 4.0; // Keep specific or make constant
    const double spacingFactor = 1.3; // Keep specific or make constant

    final RRect clipRRect = RRect.fromRectAndRadius(
       Rect.fromLTWH(offsetX, offsetY, width, height),
       // --- UPDATED: Use constant for radius factor ---
       Radius.circular(max(0, width * 0.1)), // Keep specific or make constant
    );
    canvas.clipRRect(clipRRect);

    // --- UPDATED: Use kPaletteSize constant for modulo ---
    switch (patternIndex % kPaletteSize) {
      case 0: // Horizontal Lines
        paint.style = PaintingStyle.stroke;
        for (double y = spacingY * spacingFactor; y < height; y += spacingY * spacingFactor) {
          canvas.drawLine(Offset(offsetX, offsetY + y), Offset(offsetX + width, offsetY + y), paint);
        }
        break;

      case 1: // Vertical Lines
         paint.style = PaintingStyle.stroke;
        for (double x = spacingX * spacingFactor; x < width; x += spacingX * spacingFactor) {
           canvas.drawLine(Offset(offsetX + x, offsetY), Offset(offsetX + x, offsetY + height), paint);
        }
        break;

      case 2: // Center dot
        paint.style = PaintingStyle.fill;
        // --- UPDATED: Use constant for dot size factor ---
        double dotRadius = radius * 0.5; // Keep specific or make constant
        canvas.drawCircle(Offset(centerX, centerY), dotRadius, paint);
        break;

       case 3: // Diagonal Lines (\)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         for (double d = -height; d < width; d += spacingX * spacingFactor) {
           canvas.drawLine(Offset(offsetX + d, offsetY), Offset(offsetX + d + height, offsetY + height), paint);
         }
        break;

       case 4: // Diagonal Lines (/)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         for (double d = 0; d < width + height; d += spacingX * spacingFactor) {
           canvas.drawLine(Offset(offsetX + d, offsetY), Offset(offsetX + d - height, offsetY + height), paint);
         }
         break;

      case 5: // Checkerboard -> Outline
        paint.style = PaintingStyle.stroke;
        // --- UPDATED: Use kBoxSize constant ---
        double cellW = width / kBoxSize;
        double cellH = height / kBoxSize;
        for (int i = 0; i < kBoxSize; i++) {
          for (int j = 0; j < kBoxSize; j++) {
            if ((i + j) % 2 == 0) {
              canvas.drawRect(Rect.fromLTWH(offsetX + i * cellW, offsetY + j * cellH, cellW, cellH), paint);
            }
          }
        }
        break;

      case 6: // Concentric Circles
        paint.style = PaintingStyle.stroke;
        double maxRadius = radius * 1.2; // Keep specific or make constant
        for (double r = maxRadius; r > 0; r -= maxRadius * 0.6) { // Keep specific or make constant
           if (r > paint.strokeWidth / 2) {
             canvas.drawCircle(Offset(centerX, centerY), r, paint);
           }
        }
        break;

       case 7: // Simple Grid (Crosshair)
         paint.style = PaintingStyle.stroke;
         paint.strokeCap = StrokeCap.round;
         canvas.drawLine(Offset(centerX, offsetY), Offset(centerX, offsetY + height), paint);
         canvas.drawLine(Offset(offsetX, centerY), Offset(offsetX + width, centerY), paint);
         break;

       case 8: // Center Cross (+)
          paint.style = PaintingStyle.stroke;
          paint.strokeCap = StrokeCap.round;
          // --- UPDATED: Use constants for offsets ---
          canvas.drawLine(Offset(centerX, offsetY + height * 0.15), Offset(centerX, offsetY + height * 0.85), paint); // Keep specific or make constants
          canvas.drawLine(Offset(offsetX + width * 0.15, centerY), Offset(offsetX + width * 0.85, centerY), paint); // Keep specific or make constants
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