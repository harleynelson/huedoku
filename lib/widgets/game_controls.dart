// File: lib/widgets/game_controls.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:provider/provider.dart';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class GameControls extends StatefulWidget {
  const GameControls({super.key});

  @override
  State<GameControls> createState() => GameControlsState();
}

class GameControlsState extends State<GameControls> with SingleTickerProviderStateMixin {

  late AnimationController _highlightController;
  late Animation<double> _highlightScaleAnimation;
  late Animation<Color?> _highlightColorAnimation;
  Timer? _holdTimer;

  // --- Updated triggerHighlight method (Uses constant) ---
  void triggerHighlight() {
    if (!mounted) return;
    // --- UPDATED: Use constant for hold duration ---
    const Duration holdDuration = kHighlightHoldDuration;
    _holdTimer?.cancel();

    _highlightController.forward().then((_) {
        if (mounted) {
           _holdTimer = Timer(holdDuration, () {
              if (mounted) {
                 _highlightController.reverse();
              }
           });
        }
    }).catchError((e) {
       print("Error during highlight forward animation: $e");
       if (mounted && _highlightController.isAnimating) {
          _highlightController.stop();
       }
    });
  }

  @override
  void initState() {
    super.initState();
    // --- UPDATED: Use constants for durations and scale ---
    _highlightController = AnimationController(
      duration: kHighlightAnimationDuration,
      reverseDuration: kHighlightReverseDuration,
      vsync: this,
    );

    _highlightScaleAnimation = Tween<double>(
        begin: kHighlightScaleStart,
        end: kHighlightScaleEnd)
      .animate(
        CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
  }

   @override
  void dispose() {
    _holdTimer?.cancel();
    _highlightController.dispose();
    super.dispose();
  }

  // --- Helper methods (Unchanged) ---
  CellOverlay _getNextOverlay(CellOverlay current) { switch (current) { case CellOverlay.none: return CellOverlay.numbers; case CellOverlay.numbers: return CellOverlay.patterns; case CellOverlay.patterns: return CellOverlay.none; } }
  IconData _getOverlayIcon(CellOverlay current) { switch (current) { case CellOverlay.none: return Icons.palette; case CellOverlay.numbers: return Icons.pin_outlined; case CellOverlay.patterns: return Icons.category; } }
  String _getOverlayTooltip(CellOverlay current) { switch (current) { case CellOverlay.none: return 'Show Numbers'; case CellOverlay.numbers: return 'Show Patterns'; case CellOverlay.patterns: return 'Show Colors Only'; } }


  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
     // --- UPDATED: Use constants for opacity/radius/width/blur/padding/border ---
     final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(kGlassEffectOpacity);
     final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(kLowMediumOpacity);
     const double controlCornerRadius = kMediumRadius; // Use constant
     const double maxControlsWidth = kControlMaxWidth; // Use constant

      final Color highlightStartColor = Colors.transparent;
      final Color highlightEndColor = Theme.of(context).colorScheme.primary.withOpacity(kMediumOpacity); // Use constant
      _highlightColorAnimation = ColorTween( begin: highlightStartColor, end: highlightEndColor, ).animate(CurvedAnimation(parent: _highlightController, curve: Curves.easeIn));

    return Consumer2<GameProvider, SettingsProvider>(
       builder: (context, gameProvider, settingsProvider, child) {
        final bool interactable = !gameProvider.isCompleted;
        final CellOverlay currentOverlay = settingsProvider.cellOverlay;
        bool canProvideHint = false;
        if (interactable && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { final selectedCell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!]; canProvideHint = !selectedCell.isFixed && selectedCell.value == null; }

        return Container(
           constraints: const BoxConstraints(maxWidth: maxControlsWidth),
           width: double.infinity,
           alignment: Alignment.center,
           child: ClipRRect(
              borderRadius: BorderRadius.circular(controlCornerRadius),
              child: BackdropFilter(
                // --- UPDATED: Use constant for blur ---
                filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Keep specific or make constant
                child: Container(
                  // --- UPDATED: Use constants for padding/border ---
                  padding: const EdgeInsets.symmetric(horizontal: kMediumPadding, vertical: 4.0), // Use constant
                  decoration: BoxDecoration(
                     color: glassBackgroundColor,
                     borderRadius: BorderRadius.circular(controlCornerRadius),
                     border: Border.all(color: glassBorderColor, width: 0.5), // Keep specific or make constant
                  ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                     // --- UPDATED: Use constants for elevation/opacity ---
                     FloatingActionButton.small( heroTag: 'fab_undo', tooltip: 'Undo Last Move', elevation: interactable ? kDefaultElevation : 0.0, backgroundColor: Colors.transparent, foregroundColor: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(kHighMediumOpacity), onPressed: gameProvider.canUndo && interactable ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.undo), ),
                     FloatingActionButton.small( heroTag: 'fab_edit', tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates', elevation: interactable ? kDefaultElevation : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(kHighMediumOpacity), onPressed: interactable ? gameProvider.toggleEditMode : null, child: Icon( gameProvider.isEditingCandidates ? Icons.edit_note : Icons.edit, ), ),
                     FloatingActionButton.small( heroTag: 'fab_erase', tooltip: 'Erase Cell', elevation: interactable ? kDefaultElevation : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(kHighMediumOpacity), onPressed: interactable ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.cleaning_services_outlined), ),
                     FloatingActionButton.small( heroTag: 'fab_hint', tooltip: 'Get Hint', elevation: interactable && canProvideHint ? kDefaultElevation : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable && canProvideHint ? iconColor : Colors.grey.withOpacity(kHighMediumOpacity),
                         onPressed: interactable && canProvideHint ? () {
                             bool hinted = gameProvider.provideHint(showErrors: settingsProvider.showErrors);
                             if (!hinted && context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                                     content: const Text('Select an empty cell to get a hint.'),
                                     // --- UPDATED: Use constants for duration/radius ---
                                     duration: kSnackbarDuration,
                                     behavior: SnackBarBehavior.floating,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)),
                                 ), );
                             }
                         } : null, child: const Icon(Icons.lightbulb_outline), ),
                     AnimatedBuilder( animation: _highlightController, builder: (context, child) {
                       // --- UPDATED: Use constant for scale ---
                       return Transform.scale( scale: _highlightScaleAnimation.value, child: Container( decoration: BoxDecoration( color: _highlightColorAnimation.value, shape: BoxShape.circle, ), child: child, ) ); },
                       child: FloatingActionButton.small( heroTag: 'fab_overlay_toggle', tooltip: _getOverlayTooltip(currentOverlay), elevation: interactable ? kDefaultElevation : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(kHighMediumOpacity), onPressed: interactable ? () { CellOverlay nextOverlay = _getNextOverlay(currentOverlay); settingsProvider.setCellOverlay(nextOverlay); } : null, child: Icon(_getOverlayIcon(currentOverlay)), ),
                     ),
                   ], ),
                ),
              ),
           ),
        );
       }
    );
  }
}