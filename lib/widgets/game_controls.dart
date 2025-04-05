// File: lib/widgets/game_controls.dart
// Location: ./lib/widgets/game_controls.dart
import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart'; // Import settings
import 'package:provider/provider.dart';

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color iconColor = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
     final Color activeIconColor = Theme.of(context).primaryColor;
     final Color backgroundColor = Theme.of(context).cardColor.withOpacity(0.5);

     // Access settings provider needed for erase/undo calls
     // listen: false because we only need the value when the button is pressed
     final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    return Consumer<GameProvider>(
       builder: (context, gameProvider, child) {
        // Prevent interaction if game completed
        final bool interactable = !gameProvider.isCompleted;

        return Container(
           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
           decoration: BoxDecoration(
             color: backgroundColor,
             borderRadius: BorderRadius.circular(10),
           ),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // Undo Button
              IconButton(
                icon: Icon(Icons.undo, color: gameProvider.canUndo && interactable ? iconColor : Colors.grey.withOpacity(0.5)),
                tooltip: 'Undo Last Move',
                iconSize: 28,
                // --- Pass showErrors setting ---
                onPressed: gameProvider.canUndo && interactable
                    ? () => gameProvider.performUndo(showErrors: settingsProvider.showErrors)
                    : null,
              ),

              // Edit Mode Toggle
              IconButton(
                icon: Icon(
                  gameProvider.isEditingCandidates ? Icons.edit : Icons.edit_off_outlined,
                  color: !interactable ? Colors.grey.withOpacity(0.5) : (gameProvider.isEditingCandidates ? activeIconColor : iconColor),
                ),
                tooltip: gameProvider.isEditingCandidates ? 'Place Main Colors' : 'Enter Candidates (Pencil Marks)',
                 iconSize: 28,
                 onPressed: interactable ? gameProvider.toggleEditMode : null,
              ),

              // Eraser Button
              IconButton(
                icon: Icon(Icons.cleaning_services_outlined, color: interactable ? iconColor : Colors.grey.withOpacity(0.5)),
                tooltip: 'Erase Cell',
                 iconSize: 28,
                 // --- Pass showErrors setting ---
                 onPressed: interactable
                    ? () => gameProvider.eraseSelectedCell(showErrors: settingsProvider.showErrors)
                    : null,
              ),

              // Hint Button (Placeholder)
              IconButton(
                icon: Icon(Icons.lightbulb_outline, color: interactable ? iconColor : Colors.grey.withOpacity(0.5)),
                tooltip: 'Get Hint (Not Implemented)',
                iconSize: 28,
                 onPressed: interactable
                    ? () {
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hint feature coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                       );
                    }
                    : null,
              ),
            ],
          ),
        );
       }
    );
  }
}