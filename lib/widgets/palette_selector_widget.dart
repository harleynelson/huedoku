// File: lib/widgets/palette_selector_widget.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class PaletteSelectorWidget extends StatelessWidget {
  const PaletteSelectorWidget({super.key});

  // Helper function to build a single palette item widget (Uses constants)
  Widget _buildPaletteItem(BuildContext context, int index, GameProvider gameProvider, SettingsProvider settingsProvider) {
      final List<Color> currentPalette = settingsProvider.selectedPalette.colors;
      final bool isEditingCandidates = gameProvider.isEditingCandidates;
      final bool reduceGlobal = settingsProvider.reduceCompleteGlobalOptions;
      final bool reduceLocal = settingsProvider.reduceUsedLocalOptions;
      final CellOverlay currentOverlay = settingsProvider.cellOverlay;
      // --- UPDATED: Use constants ---
      const double circleSize = kPaletteCircleSize;
      final Color defaultBorderColor = Colors.black.withOpacity(kMediumLowOpacity);
      final Color selectedBorderColor = Theme.of(context).primaryColorLight.withOpacity(kVeryHighOpacity);
      const double defaultBorderWidth = kDefaultBorderWidth;
      const double selectedBorderWidth = kSelectedCellBorderWidth; // Reuse from cell or define specific palette border
      final circleBoxShadow = [ BoxShadow( color: Colors.black.withOpacity(kLowMediumOpacity), blurRadius: 3, offset: const Offset(1, 2)) ]; // Keep specific or make constants
      const Duration transitionDuration = kShortAnimationDuration;
      final Color circleBackgroundColor = currentPalette[index];
      final Color overlayContentColor = ThemeData.estimateBrightnessForColor(circleBackgroundColor) == Brightness.dark ? Colors.white.withOpacity(0.95) : Colors.black.withOpacity(0.95); // Keep specific or make constants
      final TextStyle numberStyle = TextStyle( fontSize: kMediumFontSize, fontWeight: FontWeight.bold, color: overlayContentColor, shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(kMediumOpacity), offset: const Offset(0.5, 1)), ], ); // Keep specific or make constants
      bool isSelectedColor = false;
      if (!gameProvider.isCompleted && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { final cell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!]; if (isEditingCandidates) { isSelectedColor = cell.candidates.contains(index); } else { isSelectedColor = cell.value == index; } }
      bool isDimmed = false;
      if (!gameProvider.isCompleted) { if (reduceGlobal && gameProvider.isColorGloballyComplete(index)) { isDimmed = true; } if (!isDimmed && reduceLocal && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { if (gameProvider.isColorUsedInSelectionContext(index, gameProvider.selectedRow!, gameProvider.selectedCol!)) { isDimmed = true; } } }
      // --- UPDATED: Use constant for dimmed opacity ---
      final double itemOpacity = isDimmed ? kDimmedOpacity : kMaxOpacity;
      Widget childWidget;
      switch(currentOverlay) {
         case CellOverlay.numbers: childWidget = Center( child: Text('${index + 1}', style: numberStyle), ); break;
         // --- UPDATED: Use constant for pattern stroke multiplier ---
         case CellOverlay.patterns: childWidget = CustomPaint( painter: PatternPainter( patternIndex: index, color: overlayContentColor, strokeWidthMultiplier: kPatternStrokeMultiplier, ), child: Container(), ); break;
         case CellOverlay.none: default: childWidget = const SizedBox.shrink(); break;
      }
      return GestureDetector( onTap: isDimmed || gameProvider.isCompleted ? null : () { gameProvider.placeValue( index, showErrors: settingsProvider.showErrors ); },
        child: Opacity( opacity: itemOpacity,
          child: AnimatedContainer( duration: transitionDuration, width: circleSize, height: circleSize, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration( color: circleBackgroundColor, shape: BoxShape.circle, border: Border.all( color: isSelectedColor ? selectedBorderColor : defaultBorderColor.withOpacity(itemOpacity), width: isSelectedColor ? selectedBorderWidth : defaultBorderWidth, ), boxShadow: isDimmed ? null : circleBoxShadow, ),
            child: Center(child: childWidget), ), ), );
  }


  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Use constants ---
    const double itemSpacing = kMediumSpacing;
    const double runSpacing = kSmallSpacing;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(kLowMediumOpacity);
    final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.25); // Keep specific or make constant
    const double paletteContainerCornerRadius = kMediumRadius;
    const double maxPaletteWidth = kPaletteMaxWidth;

    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, gameProvider, settingsProvider, child) {
        if (!gameProvider.isPuzzleLoaded) {
          return const SizedBox.shrink();
        }

        // --- UPDATED: Use kPaletteSize constant potentially if rows change ---
        List<Widget> firstRowWidgets = [];
        for (int i = 0; i < 5; i++) { firstRowWidgets.add(_buildPaletteItem(context, i, gameProvider, settingsProvider)); if (i < 4) { firstRowWidgets.add(const SizedBox(width: itemSpacing)); } }
        List<Widget> secondRowWidgets = [];
        for (int i = 5; i < kPaletteSize; i++) { secondRowWidgets.add(_buildPaletteItem(context, i, gameProvider, settingsProvider)); if (i < (kPaletteSize - 1)) { secondRowWidgets.add(const SizedBox(width: itemSpacing)); } }

        return Container(
           constraints: const BoxConstraints(maxWidth: maxPaletteWidth),
           width: double.infinity,
           alignment: Alignment.center,
           child: ClipRRect(
              borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
              child: BackdropFilter(
                // --- UPDATED: Use constant for blur ---
                filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0), // Keep specific or make constant
                child: Container(
                   // --- UPDATED: Use constants for padding/border ---
                   padding: const EdgeInsets.symmetric(vertical: kMediumSpacing, horizontal: kDefaultPadding),
                   decoration: BoxDecoration(
                     color: glassBackgroundColor,
                     borderRadius: BorderRadius.circular(paletteContainerCornerRadius),
                     border: Border.all(color: glassBorderColor, width: 0.5), // Keep specific or make constant
                   ),
                   child: Column(
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
      },
    );
  }
}