// File: lib/widgets/palette_selector_widget.dart
// Location: ./lib/widgets/palette_selector_widget.dart

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

        // Define base styles for the circle container
        const double circleSize = 38.0;
        final Color defaultBorderColor = Colors.black.withOpacity(0.2);
        final Color selectedBorderColor = isDarkMode ? Colors.tealAccent[100]!.withOpacity(0.8) : Colors.teal[300]!;
        const double defaultBorderWidth = 1.5;
        const double selectedBorderWidth = 3.0;
        final circleBoxShadow = [
           BoxShadow( color: Colors.black.withOpacity(0.15), blurRadius: 2, offset: const Offset(1, 1))
        ];


        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 6.0,
            children: List.generate(9, (index) {
              final Color circleBackgroundColor = currentPalette[index]; // Use palette color as background

              // --- Calculate contrasting overlay color ---
              final Color overlayContentColor =
                  ThemeData.estimateBrightnessForColor(circleBackgroundColor) == Brightness.dark
                      ? Colors.white.withOpacity(0.9) // Slightly more opaque white
                      : Colors.black.withOpacity(0.9); // Slightly more opaque black

              // Define styles for numbers using the contrast color
               final TextStyle numberStyle = TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: overlayContentColor,
                    shadows: [ // Add subtle shadow like in cell widget
                     Shadow(blurRadius: 1.0, color: Colors.black.withOpacity(0.25), offset: const Offset(0.5, 0.5)),
                   ],
               );


              // Determine if this index is the selected one
              bool isSelectedColor = false;
              if (!gameProvider.isCompleted && gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
                  final cell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!];
                   if (!isEditingCandidates && cell.value == index) isSelectedColor = true;
                   else if (isEditingCandidates && cell.candidates.contains(index)) isSelectedColor = true;
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
                            strokeWidthMultiplier: 0.12, // Adjusted for smaller circles
                         ),
                         child: Container(), // Needed for CustomPaint to size correctly
                     );
                     break;
                 case CellOverlay.none:
                 default:
                    childWidget = const SizedBox.shrink(); // No child needed for color only
                    break;
              }

              return GestureDetector(
                onTap: () {
                  if (!gameProvider.isCompleted) {
                      gameProvider.placeValue( index, showErrors: settingsProvider.showErrors );
                  }
                },
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  clipBehavior: Clip.antiAlias, // Use antiAlias for smoother circle clip
                  decoration: BoxDecoration(
                    // Background is ALWAYS the palette color now
                    color: circleBackgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelectedColor ? selectedBorderColor : defaultBorderColor,
                      width: isSelectedColor ? selectedBorderWidth : defaultBorderWidth,
                    ),
                    boxShadow: circleBoxShadow,
                  ),
                  // Add the conditional child (Number, Pattern, or Empty)
                  // Use Center to ensure painter/text is centered if it doesn't fill
                  child: Center(child: childWidget),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}