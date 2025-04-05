// File: lib/widgets/game_controls.dart
// Location: ./lib/widgets/game_controls.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart'; // Import settings
import 'package:provider/provider.dart';

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
Widget build(BuildContext context) {
   final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
   // Use theme colors for icons for better consistency
   final Color iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.grey[300]! : Colors.grey[700]!);
   final Color activeIconColor = Theme.of(context).primaryColor;
   // Glass effect background
   final Color glassBackgroundColor = (isDarkMode ? Colors.black : Colors.white).withOpacity(0.15);
   final Color glassBorderColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2);


   // Access settings provider needed for erase/undo calls
   // listen: false because we only need the value when the button is pressed
   final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

   // Define consistent corner radius
   const double controlCornerRadius = 16.0;

  return Consumer<GameProvider>(
     builder: (context, gameProvider, child) {
      // Prevent interaction if game completed
      final bool interactable = !gameProvider.isCompleted;

      // Use ClipRRect + BackdropFilter for glass effect
      return ClipRRect(
         borderRadius: BorderRadius.circular(controlCornerRadius),
         child: BackdropFilter(
           filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Adjust blur amount
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Adjust padding
             decoration: BoxDecoration(
               color: glassBackgroundColor,
               borderRadius: BorderRadius.circular(controlCornerRadius),
               border: Border.all(color: glassBorderColor, width: 0.5),
             ),
             child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // Undo Button - Using FAB small
                FloatingActionButton.small(
                  heroTag: 'fab_undo', // Unique heroTag needed for multiple FABs
                  tooltip: 'Undo Last Move',
                  elevation: interactable ? 2.0 : 0.0,
                  backgroundColor: Colors.transparent, // Let foreground color dominate
                  foregroundColor: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(0.5),
                  // --- Pass showErrors setting ---
                  onPressed: gameProvider.canUndo && interactable
                      ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors)
                      : null,
                  child: const Icon(Icons.undo),
                ),

                // Edit Mode Toggle - Using FAB small
                FloatingActionButton.small(
                   heroTag: 'fab_edit',
                  tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates',
                  elevation: interactable ? 2.0 : 0.0,
                  backgroundColor: Colors.transparent,
                   foregroundColor: !interactable ? Colors.grey.withOpacity(0.5) : (gameProvider.isEditingCandidates ? activeIconColor : iconColor),
                   onPressed: interactable ? gameProvider.toggleEditMode : null,
                   child: Icon(
                     gameProvider.isEditingCandidates ? Icons.edit_note : Icons.edit_off_outlined, // Changed icon
                   ),
                ),

                // Eraser Button - Using FAB small
                 FloatingActionButton.small(
                   heroTag: 'fab_erase',
                   tooltip: 'Erase Cell',
                   elevation: interactable ? 2.0 : 0.0,
                   backgroundColor: Colors.transparent,
                   foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5),
                   // --- Pass showErrors setting ---
                   onPressed: interactable
                      ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors)
                      : null,
                   child: const Icon(Icons.cleaning_services_outlined),
                 ),

                // Hint Button (Placeholder) - Using FAB small
                FloatingActionButton.small(
                  heroTag: 'fab_hint',
                  tooltip: 'Get Hint (Not Implemented)',
                  elevation: interactable ? 2.0 : 0.0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: interactable ? iconColor : Colors.grey.withOpacity(0.5),
                   onPressed: interactable
                      ? () {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Hint feature coming soon!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating, // More modern look
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                         );
                      }
                      : null,
                   child: const Icon(Icons.lightbulb_outline),
                ),
              ],
            ),
           ),
         ),
      );
     }
  );
}
}