// File: lib/widgets/palette_selector_widget.dart
// Location: ./lib/widgets/palette_selector_widget.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // For min function if needed for sizing

class PaletteSelectorWidget extends StatelessWidget {
  const PaletteSelectorWidget({super.key});

  // Helper function to build a single palette item widget (Unchanged)
  Widget _buildPaletteItem(BuildContext context, int index, GameProvider gameProvider, SettingsProvider settingsProvider) {
      final List<Color> currentPalette = settingsProvider.selectedPalette.colors;
      final bool isEditingCandidates = gameProvider.isEditingCandidates;
      final bool reduceGlobal = settingsProvider.reduceCompleteGlobalOptions;
      final bool reduceLocal = settingsProvider.reduceUsedLocalOptions;
      final CellOverlay currentOverlay = settingsProvider.cellOverlay;
      const double circleSize = 40.0;
      final Color defaultBorderColor = Colors.black.withOpacity(0.15);
      final Color selectedBorderColor = Theme.of(context).primaryColorLight.withOpacity(0.9);
      const double defaultBorderWidth = 1.0;
      const double selectedBorderWidth = 3.5;
      final circleBoxShadow = [ BoxShadow( color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(1, 2)) ];
      const Duration transitionDuration = Duration(milliseconds: 150);
      final Color circleBackgroundColor = currentPalette[index];
      final Color overlayContentColor = ThemeData.estimateBrightnessForColor(circleBackgroundColor) == Brightness.dark ? Colors.white.withOpacity(0.95) : Colors.black.withOpacity(0.95);
      final TextStyle numberStyle = TextStyle( fontSize: 17, fontWeight: FontWeight.bold, color: overlayContentColor, shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1)), ], );
      bool isSelectedColor = false;
      if (!gameProvider.isCompleted && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { final cell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!]; if (isEditingCandidates) { isSelectedColor = cell.candidates.contains(index); } else { isSelectedColor = cell.value == index; } }
      bool isDimmed = false;
      if (!gameProvider.isCompleted) { if (reduceGlobal && gameProvider.isColorGloballyComplete(index)) { isDimmed = true; } if (!isDimmed && reduceLocal && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { if (gameProvider.isColorUsedInSelectionContext(index, gameProvider.selectedRow!, gameProvider.selectedCol!)) { isDimmed = true; } } }
      final double itemOpacity = isDimmed ? 0.3 : 1.0;
      Widget childWidget;
      switch(currentOverlay) { case CellOverlay.numbers: childWidget = Center( child: Text('${index + 1}', style: numberStyle), ); break; case CellOverlay.patterns: childWidget = CustomPaint( painter: PatternPainter( patternIndex: index, color: overlayContentColor, strokeWidthMultiplier: 0.13, ), child: Container(), ); break; case CellOverlay.none: default: childWidget = const SizedBox.shrink(); break; }
      return GestureDetector( onTap: isDimmed || gameProvider.isCompleted ? null : () { gameProvider.placeValue( index, showErrors: settingsProvider.showErrors ); },
        child: Opacity( opacity: itemOpacity,
          child: AnimatedContainer( duration: transitionDuration, width: circleSize, height: circleSize, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration( color: circleBackgroundColor, shape: BoxShape.circle, border: Border.all( color: isSelectedColor ? selectedBorderColor : defaultBorderColor.withOpacity(itemOpacity), width: isSelectedColor ? selectedBorderWidth : defaultBorderWidth, ), boxShadow: isDimmed ? null : circleBoxShadow, ),
            child: Center(child: childWidget), ), ), );
  }


  @override
  Widget build(BuildContext context) {
    const double itemSpacing = 10.0;
    const double runSpacing = 8.0;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.20);
    final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.25);
    const double paletteContainerCornerRadius = 16.0;
    // --- Define Max Width for Palette Selector ---
    const double maxPaletteWidth = 350.0; // Adjust as needed

    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, gameProvider, settingsProvider, child) {
        if (!gameProvider.isPuzzleLoaded) {
          return const SizedBox.shrink();
        }

        // Build Widgets for each row (Unchanged)
        List<Widget> firstRowWidgets = [];
        for (int i = 0; i < 5; i++) { firstRowWidgets.add(_buildPaletteItem(context, i, gameProvider, settingsProvider)); if (i < 4) { firstRowWidgets.add(const SizedBox(width: itemSpacing)); } }
        List<Widget> secondRowWidgets = [];
        for (int i = 5; i < 9; i++) { secondRowWidgets.add(_buildPaletteItem(context, i, gameProvider, settingsProvider)); if (i < 8) { secondRowWidgets.add(const SizedBox(width: itemSpacing)); } }

        // --- Apply Max Width Constraint ---
        return Container( // Outer container to control width and center alignment
           constraints: const BoxConstraints(maxWidth: maxPaletteWidth),
           width: double.infinity, // Try to take available width up to max
           alignment: Alignment.center, // Center the inner content
           child: ClipRRect(
              borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Container( // Inner container for styling (padding, background)
                   // No width constraint here, let the outer container handle it
                   padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                   decoration: BoxDecoration(
                     color: glassBackgroundColor,
                     borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
                     border: Border.all(color: glassBorderColor, width: 0.5),
                   ),
                   child: Column( // Column containing the rows
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row( mainAxisAlignment: MainAxisAlignment.center, children: firstRowWidgets, ),
                        const SizedBox(height: runSpacing),
                        Row( mainAxisAlignment: MainAxisAlignment.center, children: secondRowWidgets, ),
                      ],
                   )
                 ),
               ),
            ),
         );
        // --- End Apply Max Width Constraint ---
      },
    );
  }
}