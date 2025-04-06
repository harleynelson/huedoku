// File: lib/widgets/game_controls.dart
// Location: ./lib/widgets/game_controls.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart'; // Import CellOverlay enum
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  // Helper functions (_getNextOverlay, _getOverlayIcon, _getOverlayTooltip) remain unchanged
  CellOverlay _getNextOverlay(CellOverlay current) {
    switch (current) { case CellOverlay.none: return CellOverlay.numbers; case CellOverlay.numbers: return CellOverlay.patterns; case CellOverlay.patterns: return CellOverlay.none; }
  }
  IconData _getOverlayIcon(CellOverlay current) {
     switch (current) { case CellOverlay.none: return Icons.grid_off_outlined; case CellOverlay.numbers: return Icons.pin_outlined; case CellOverlay.patterns: return Icons.pattern_outlined; }
  }
  String _getOverlayTooltip(CellOverlay current) {
     switch (current) { case CellOverlay.none: return 'Show Numbers'; case CellOverlay.numbers: return 'Show Patterns'; case CellOverlay.patterns: return 'Show Colors Only'; }
  }


  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
     // activeIconColor removed as it wasn't needed for the edit button override
     final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.15);
     final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2);
     const double controlCornerRadius = 16.0;
     // --- Define Max Width Constraint ---
     const double maxControlsWidth = 350.0; // Match Palette Selector


    // Use Consumer2 to listen to both providers
    return Consumer2<GameProvider, SettingsProvider>(
       builder: (context, gameProvider, settingsProvider, child) {
        final bool interactable = !gameProvider.isCompleted;
        final CellOverlay currentOverlay = settingsProvider.cellOverlay;
        bool canProvideHint = false;
        if (interactable && gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
            final selectedCell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!];
            canProvideHint = !selectedCell.isFixed && selectedCell.value == null;
        }

        // --- Apply Max Width Constraint ---
        return Container( // Outer container to control width and center alignment
           constraints: const BoxConstraints(maxWidth: maxControlsWidth),
           width: double.infinity, // Try to take available width up to max
           alignment: Alignment.center, // Center the inner content
           child: ClipRRect( // Original root widget is now child of Container
              borderRadius: BorderRadius.circular(controlCornerRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  // Remove width constraint from here, let outer container handle it
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: glassBackgroundColor,
                    borderRadius: BorderRadius.circular(controlCornerRadius),
                    border: Border.all(color: glassBorderColor, width: 0.5),
                  ),
                  child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: <Widget>[
                     // Undo Button (Unchanged)
                     FloatingActionButton.small( heroTag: 'fab_undo', tooltip: 'Undo Last Move', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: gameProvider.canUndo && interactable ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.undo), ),
                     // Edit Mode Toggle (Unchanged logic, color fixed previously)
                     FloatingActionButton.small( heroTag: 'fab_edit', tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? gameProvider.toggleEditMode : null, child: Icon( gameProvider.isEditingCandidates ? Icons.edit_note : Icons.edit_off_outlined, ), ),
                     // Eraser Button (Unchanged)
                      FloatingActionButton.small( heroTag: 'fab_erase', tooltip: 'Erase Cell', elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors) : null, child: const Icon(Icons.cleaning_services_outlined), ),
                     // Hint Button (Unchanged)
                     FloatingActionButton.small( heroTag: 'fab_hint', tooltip: 'Get Hint', elevation: interactable && canProvideHint ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable && canProvideHint ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable && canProvideHint ? () { bool hinted = gameProvider.provideHint(showErrors: settingsProvider.showErrors); if (!hinted && context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Select an empty cell to get a hint.'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), ), ); } } : null, child: const Icon(Icons.lightbulb_outline), ),
                     // Cell Overlay Toggle Button (Unchanged)
                     FloatingActionButton.small( heroTag: 'fab_overlay_toggle', tooltip: _getOverlayTooltip(currentOverlay), elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5), onPressed: interactable ? () { CellOverlay nextOverlay = _getNextOverlay(currentOverlay); settingsProvider.setCellOverlay(nextOverlay); } : null, child: Icon(_getOverlayIcon(currentOverlay)), ),
                   ],
                  ),
                 ),
               ),
            ),
         );
       // --- End Apply Max Width Constraint ---
       }
    );
  }
}