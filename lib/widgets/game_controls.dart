// File: lib/widgets/game_controls.dart
// Location: Entire File
import 'dart:async'; // Import Timer
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class GameControls extends StatefulWidget {
  const GameControls({super.key});

  @override
  State<GameControls> createState() => GameControlsState();
}

class GameControlsState extends State<GameControls> with SingleTickerProviderStateMixin {

  late AnimationController _highlightController;
  late Animation<double> _highlightScaleAnimation;
  late Animation<Color?> _highlightColorAnimation;
  Timer? _holdTimer; // Timer for the hold duration

  // --- Updated triggerHighlight method ---
  void triggerHighlight() {
    if (!mounted) return;

    // Define the hold duration
    const Duration holdDuration = Duration(milliseconds: 2000); // Hold for 2 seconds

    // Cancel any previous hold timer
    _holdTimer?.cancel();

    // Start the forward (pulse in) animation
    _highlightController.forward().then((_) {
        // After forward completes, start the hold timer
        if (mounted) {
           _holdTimer = Timer(holdDuration, () {
              // After the hold duration, start the reverse (fade out) animation
              if (mounted) {
                 _highlightController.reverse();
              }
           });
        }
    }).catchError((e) {
       // Handle potential errors if the controller is disposed during animation
       print("Error during highlight forward animation: $e");
       if (mounted && _highlightController.isAnimating) {
          _highlightController.stop(); // Stop animation if error occurs
       }
    });
  }
  // --- End updated method ---

  @override
  void initState() {
    super.initState();
    // Keep the animation durations as they were (or adjust as needed)
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 500), // Pulse in duration
      reverseDuration: const Duration(milliseconds: 1000), // Fade out duration
      vsync: this,
    );

    _highlightScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
    // Color animation setup moved to build
  }

   @override
  void dispose() {
    _holdTimer?.cancel(); // Cancel timer on dispose
    _highlightController.dispose();
    super.dispose();
  }

  // --- Helper methods (unchanged) ---
  CellOverlay _getNextOverlay(CellOverlay current) { switch (current) { case CellOverlay.none: return CellOverlay.numbers; case CellOverlay.numbers: return CellOverlay.patterns; case CellOverlay.patterns: return CellOverlay.none; } }
  IconData _getOverlayIcon(CellOverlay current) { switch (current) { case CellOverlay.none: return Icons.grid_off_outlined; case CellOverlay.numbers: return Icons.pin_outlined; case CellOverlay.patterns: return Icons.pattern_outlined; } }
  String _getOverlayTooltip(CellOverlay current) { switch (current) { case CellOverlay.none: return 'Show Numbers'; case CellOverlay.numbers: return 'Show Patterns'; case CellOverlay.patterns: return 'Show Colors Only'; } }


  @override
  Widget build(BuildContext context) {
     // --- Build method structure (unchanged) ---
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
     final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.15);
     final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2);
     const double controlCornerRadius = 16.0;
     const double maxControlsWidth = 350.0;

      final Color highlightStartColor = Colors.transparent;
      final Color highlightEndColor = Theme.of(context).colorScheme.primary.withOpacity(0.3);
      _highlightColorAnimation = ColorTween( begin: highlightStartColor, end: highlightEndColor, ).animate(CurvedAnimation(parent: _highlightController, curve: Curves.easeIn));

    return Consumer2<GameProvider, SettingsProvider>(
       builder: (context, gameProvider, settingsProvider, child) {
        final bool interactable = !gameProvider.isCompleted;
        final CellOverlay currentOverlay = settingsProvider.cellOverlay;
        bool canProvideHint = false;
        if (interactable && gameProvider.selectedRow != null && gameProvider.selectedCol != null) { final selectedCell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!]; canProvideHint = !selectedCell.isFixed && selectedCell.value == null; }

        return Container( constraints: const BoxConstraints(maxWidth: maxControlsWidth), width: double.infinity, alignment: Alignment.center,
           child: ClipRRect( borderRadius: BorderRadius.circular(controlCornerRadius),
              child: BackdropFilter( filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container( padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), decoration: BoxDecoration( color: glassBackgroundColor, borderRadius: BorderRadius.circular(controlCornerRadius), border: Border.all(color: glassBorderColor, width: 0.5), ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                     // Buttons remain the same...
                     FloatingActionButton.small( heroTag: 'fab_undo', tooltip: 'Undo Last Move', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: gameProvider.canUndo && interactable ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.undo), ),
                     FloatingActionButton.small( heroTag: 'fab_edit', tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? gameProvider.toggleEditMode : null, child: Icon( gameProvider.isEditingCandidates ? Icons.edit_note : Icons.edit_off_outlined, ), ),
                     FloatingActionButton.small( heroTag: 'fab_erase', tooltip: 'Erase Cell', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.cleaning_services_outlined), ),
                     FloatingActionButton.small( heroTag: 'fab_hint', tooltip: 'Get Hint', elevation: interactable && canProvideHint ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable && canProvideHint ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable && canProvideHint ? () { bool hinted = gameProvider.provideHint(showErrors: settingsProvider.showErrors); if (!hinted && context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Select an empty cell to get a hint.'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), ), ); } } : null, child: const Icon(Icons.lightbulb_outline), ),
                     // Animated Cell Overlay Toggle Button
                     AnimatedBuilder( animation: _highlightController, builder: (context, child) { return Transform.scale( scale: _highlightScaleAnimation.value, child: Container( decoration: BoxDecoration( color: _highlightColorAnimation.value, shape: BoxShape.circle, ), child: child, ) ); },
                       child: FloatingActionButton.small( heroTag: 'fab_overlay_toggle', tooltip: _getOverlayTooltip(currentOverlay), elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? () { CellOverlay nextOverlay = _getNextOverlay(currentOverlay); settingsProvider.setCellOverlay(nextOverlay); } : null, child: Icon(_getOverlayIcon(currentOverlay)), ), ),
                   ], ), ), ), ), );
       }
    );
  }
}