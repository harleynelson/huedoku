// File: lib/widgets/palette_selector_widget.dart
// Location: ./lib/widgets/palette_selector_widget.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart'; // Needed for CellOverlay enum
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart'; // Import pattern painter
import 'package:provider/provider.dart';
import 'dart:math'; // For min function if needed for sizing

class PaletteSelectorWidget extends StatelessWidget {
  const PaletteSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume both providers
    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, gameProvider, settingsProvider, child) {
        if (!gameProvider.isPuzzleLoaded) {
          return const SizedBox.shrink();
        }

        final List<Color> currentPalette = settingsProvider.selectedPalette.colors;
        final bool isEditingCandidates = gameProvider.isEditingCandidates;
        final CellOverlay currentOverlay = settingsProvider.cellOverlay;
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        // --- Get the two new setting values ---
        final bool reduceLocal = settingsProvider.reduceUsedLocalOptions;
        final bool reduceGlobal = settingsProvider.reduceCompleteGlobalOptions;

        // Define base styles for the circle container
        const double circleSize = 40.0; // Slightly larger circles
        final Color defaultBorderColor = Colors.black.withOpacity(0.15);
        final Color selectedBorderColor = Theme.of(context).primaryColorLight.withOpacity(0.9); // Lighter selection border
        const double defaultBorderWidth = 1.0; // Thinner default border
        const double selectedBorderWidth = 3.5; // Thicker selection border
        final circleBoxShadow = [
           BoxShadow( color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(1, 2)) // Slightly stronger shadow
        ];

        // Glass effect background for the Wrap container
        final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.20); // More transparent
        final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.25);
        const double paletteContainerCornerRadius = 16.0; // Consistent radius

        return ClipRRect( // Apply clipping for glass effect
          borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
          child: BackdropFilter( // Apply blur effect
            filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Adjust padding
              decoration: BoxDecoration(
                color: glassBackgroundColor, // Semi-transparent background
                borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
                border: Border.all(color: glassBorderColor, width: 0.5),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10.0, // Increased spacing
                runSpacing: 8.0, // Increased run spacing
                children: List.generate(9, (index) {
                  final Color circleBackgroundColor = currentPalette[index]; // Use palette color as background

                  // --- Calculate contrasting overlay color ---
                  final Color overlayContentColor =
                      ThemeData.estimateBrightnessForColor(circleBackgroundColor) == Brightness.dark
                          ? Colors.white.withOpacity(0.95) // More opaque white
                          : Colors.black.withOpacity(0.95); // More opaque black

                  // Define styles for numbers using the contrast color
                   final TextStyle numberStyle = TextStyle(
                       fontSize: 17, // Slightly larger font
                       fontWeight: FontWeight.bold,
                       color: overlayContentColor,
                        shadows: [ // Add subtle shadow like in cell widget
                         Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1)),
                       ],
                   );


                  // Determine if this index is the selected one
                  bool isSelectedColor = false;
                  if (!gameProvider.isCompleted && gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
                      final cell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!];
                       // Check based on edit mode and cell state
                       if (isEditingCandidates) {
                           isSelectedColor = cell.candidates.contains(index);
                       } else {
                           isSelectedColor = cell.value == index;
                       }
                  }

                  // --- Determine Child Widget based on Overlay Setting ---
                  Widget childWidget;

                  switch(currentOverlay) {
                     case CellOverlay.numbers:
                        childWidget = Center(
                            child: Text('${index + 1}', style: numberStyle),
                        );
                        break;
                     case CellOverlay.patterns:
                         childWidget = CustomPaint(
                             painter: PatternPainter(
                                patternIndex: index,
                                // Use the calculated contrasting color
                                color: overlayContentColor,
                                strokeWidthMultiplier: 0.13, // Slightly thicker pattern
                             ),
                             child: Container(), // Needed for CustomPaint to size correctly
                         );
                         break;
                     case CellOverlay.none:
                     default:
                        childWidget = const SizedBox.shrink(); // No child needed for color only
                        break;
                  }

                  // --- Check if this option should be dimmed (combined logic) ---
                  bool isDimmed = false;
                  if (!gameProvider.isCompleted) { // Only dim if game is not over
                     // Check global completion setting first
                     if (reduceGlobal && gameProvider.isColorGloballyComplete(index)) {
                         isDimmed = true;
                     }
                     // If not dimmed by global check, check local usage setting
                     if (!isDimmed && reduceLocal && gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
                        if (gameProvider.isColorUsedInSelectionContext(index, gameProvider.selectedRow!, gameProvider.selectedCol!)) {
                            isDimmed = true;
                        }
                     }
                  }
                  // --- End dim check ---

                  // Use a common transition duration
                  const Duration transitionDuration = Duration(milliseconds: 150);
                  // Define opacity based on dimmed state
                  final double itemOpacity = isDimmed ? 0.3 : 1.0; // Dim to 30% opacity

                  return GestureDetector(
                    // Disable tap if dimmed or game is completed
                    onTap: isDimmed || gameProvider.isCompleted ? null : () {
                          gameProvider.placeValue( index, showErrors: settingsProvider.showErrors );
                    },
                    child: Opacity( // Apply opacity based on dimmed state
                      opacity: itemOpacity,
                      child: AnimatedContainer( // Animate the border change
                        duration: transitionDuration,
                        width: circleSize,
                        height: circleSize,
                        clipBehavior: Clip.antiAlias, // Use antiAlias for smoother circle clip
                        decoration: BoxDecoration(
                          // Background is ALWAYS the palette color now
                          color: circleBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            // Dim border if item is dimmed
                            color: isSelectedColor ? selectedBorderColor : defaultBorderColor.withOpacity(itemOpacity),
                            width: isSelectedColor ? selectedBorderWidth : defaultBorderWidth,
                          ),
                          // Dim shadow if item is dimmed
                          boxShadow: isDimmed ? null : circleBoxShadow,
                        ),
                        // Add the conditional child (Number, Pattern, or Empty)
                        // Use Center to ensure painter/text is centered if it doesn't fill
                        child: Center(child: childWidget),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}