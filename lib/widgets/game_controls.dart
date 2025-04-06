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

  // Helper to get next overlay mode
  CellOverlay _getNextOverlay(CellOverlay current) {
    switch (current) {
      case CellOverlay.none:
        return CellOverlay.numbers;
      case CellOverlay.numbers:
        return CellOverlay.patterns;
      case CellOverlay.patterns:
        return CellOverlay.none;
    }
  }

  // Helper to get icon based on overlay mode
  IconData _getOverlayIcon(CellOverlay current) {
     switch (current) {
      case CellOverlay.none:
        // Represents 'Color Only' - maybe visibility off or grid off?
        return Icons.grid_off_outlined; // Or Icons.visibility_off_outlined
      case CellOverlay.numbers:
        // Represents numbers
        return Icons.pin_outlined; // Or Icons.looks_one
      case CellOverlay.patterns:
        // Represents patterns
        return Icons.pattern_outlined; // Or Icons.texture
    }
  }

    // Helper to get tooltip based on overlay mode
  String _getOverlayTooltip(CellOverlay current) {
     switch (current) {
      case CellOverlay.none:
        return 'Show Numbers'; // Tooltip describes the *next* state
      case CellOverlay.numbers:
        return 'Show Patterns';
      case CellOverlay.patterns:
        return 'Show Colors Only';
    }
  }


  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
     final Color activeIconColor = Theme.of(context).primaryColor;
     final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.15);
     final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2);
     const double controlCornerRadius = 16.0;


    // Use Consumer2 to listen to both providers
    return Consumer2<GameProvider, SettingsProvider>(
       builder: (context, gameProvider, settingsProvider, child) {
        // Prevent interaction if game completed
        final bool interactable = !gameProvider.isCompleted;
        // Get current overlay state from settingsProvider
        final CellOverlay currentOverlay = settingsProvider.cellOverlay;

        bool canProvideHint = false;
        if (interactable && gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
            final selectedCell = gameProvider.board[gameProvider.selectedRow!][gameProvider.selectedCol!];
            canProvideHint = !selectedCell.isFixed && selectedCell.value == null;
        }

        return ClipRRect(
           borderRadius: BorderRadius.circular(controlCornerRadius),
           child: BackdropFilter(
             filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
               decoration: BoxDecoration(
                 color: glassBackgroundColor,
                 borderRadius: BorderRadius.circular(controlCornerRadius),
                 border: Border.all(color: glassBorderColor, width: 0.5),
               ),
               child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // Undo Button
                  FloatingActionButton.small(
                    heroTag: 'fab_undo', tooltip: 'Undo Last Move', elevation: interactable ? 2.0 : 0.0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(0.5),
                    onPressed: gameProvider.canUndo && interactable
                        ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors) : null,
                    child: const Icon(Icons.undo),
                  ),

                  // Edit Mode Toggle
                  FloatingActionButton.small(
                     heroTag: 'fab_edit', tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates',
                    elevation: interactable ? 2.0 : 0.0, backgroundColor: Colors.transparent,
                     foregroundColor: !interactable ? Colors.grey.withOpacity(0.5) : (gameProvider.isEditingCandidates ? activeIconColor : iconColor),
                     onPressed: interactable ? gameProvider.toggleEditMode : null,
                     child: Icon( gameProvider.isEditingCandidates ? Icons.edit_note : Icons.edit_off_outlined, ),
                  ),

                  // Eraser Button
                   FloatingActionButton.small(
                     heroTag: 'fab_erase', tooltip: 'Erase Cell', elevation: interactable ? 2.0 : 0.0,
                     backgroundColor: Colors.transparent, foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5),
                     onPressed: interactable ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors) : null,
                     child: const Icon(Icons.cleaning_services_outlined),
                   ),

                  // Hint Button
                  FloatingActionButton.small(
                    heroTag: 'fab_hint', tooltip: 'Get Hint', elevation: interactable && canProvideHint ? 2.0 : 0.0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: interactable && canProvideHint ? iconColor : Colors.grey.withOpacity(0.5),
                     onPressed: interactable && canProvideHint
                        ? () { /* ... hint logic ... */
                           bool hinted = gameProvider.provideHint(showErrors: settingsProvider.showErrors);
                            if (!hinted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Select an empty cell to get a hint.'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), ), ); } }
                        : null,
                     child: const Icon(Icons.lightbulb_outline),
                  ),

                  // --- NEW Cell Overlay Toggle Button ---
                  FloatingActionButton.small(
                    heroTag: 'fab_overlay_toggle',
                    // Tooltip describes the action (what the *next* state will be)
                    tooltip: _getOverlayTooltip(currentOverlay),
                    elevation: interactable ? 2.0 : 0.0,
                    backgroundColor: Colors.transparent,
                    // Icon represents the *current* state
                    foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5),
                    onPressed: interactable ? () {
                       // Calculate the next overlay state
                       CellOverlay nextOverlay = _getNextOverlay(currentOverlay);
                       // Update the setting using the provider (listen: false needed if called from onPressed)
                       // Note: Consumer2 builder already provides settingsProvider, no need for Provider.of here
                       settingsProvider.setCellOverlay(nextOverlay);
                    } : null,
                    // Icon reflects the current state
                    child: Icon(_getOverlayIcon(currentOverlay)),
                  ),
                  // --- END NEW Button ---
                ],
              ),
             ),
           ),
        );
       }
    );
  }
}