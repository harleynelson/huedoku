// File: lib/widgets/settings_content.dart
// Location: ./lib/widgets/settings_content.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart'; // Import GameProvider
import 'package:huedoku/providers/settings_provider.dart';
import 'package:provider/provider.dart';

// Widget containing the actual settings options, designed to be reusable
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  // Helper to get user-friendly names for overlays
  String _cellOverlayDescription(CellOverlay overlay) {
    switch (overlay) {
      case CellOverlay.none: return 'Color Only';
      case CellOverlay.numbers: return 'Show Numbers (1-9)';
      case CellOverlay.patterns: return 'Show Patterns';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access GameProvider here for use in onChanged callback
    // listen: false because we only need to call methods, not react to game state changes here
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: ListView(
        shrinkWrap: true, // Important for use in bottom sheet
        children: <Widget>[
          // --- Appearance Section ---
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),

          // Palette Selection
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return ListTile(
                title: const Text('Color Palette'),
                subtitle: Text(settings.selectedPalette.name),
                trailing: const Icon(Icons.color_lens),
                onTap: () async {
                  // Show dialog to select palette
                  final selected = await showDialog<ColorPalette>(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('Select Palette'),
                        children: ColorPalette.defaultPalettes.map((palette) {
                          return SimpleDialogOption(
                            onPressed: () {
                              Navigator.pop(context, palette);
                            },
                            child: Row(
                              children: [
                                // Small preview of the palette
                                Row(
                                  children: palette.colors.take(5).map((c) => Container(
                                    width: 15, height: 15, color: c, margin: const EdgeInsets.only(right: 2)
                                  )).toList(),
                                ),
                                const SizedBox(width: 10),
                                Text(palette.name),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                  if (selected != null) {
                    settings.setSelectedPalette(selected);
                  }
                },
              );
            },
          ),

           // Dark Mode Toggle
           Consumer<SettingsProvider>(
             builder: (context, settings, child) {
               return SwitchListTile(
                 title: const Text('Dark Mode'),
                 value: settings.isDarkMode,
                 onChanged: (value) {
                   settings.setIsDarkMode(value);
                 },
               );
             }
           ),

          const SizedBox(height: 20),

          // --- Gameplay Section ---
          Text('Gameplay', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),

          // Cell Overlay Setting
          Consumer<SettingsProvider>(
             builder: (context, settings, child) {
              return ListTile(
                 title: const Text('Cell Overlay'),
                 subtitle: Text(_cellOverlayDescription(settings.cellOverlay)),
                 trailing: const Icon(Icons.visibility),
                 onTap: () async {
                    final selected = await showDialog<CellOverlay>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                           title: const Text('Select Cell Overlay'),
                           children: CellOverlay.values.map((overlay) {
                             return SimpleDialogOption(
                                onPressed: () { Navigator.pop(context, overlay); },
                                child: Text(_cellOverlayDescription(overlay)),
                             );
                           }).toList(),
                        );
                      }
                    );
                     if (selected != null) {
                      settings.setCellOverlay(selected);
                    }
                 },
               );
             }
          ),

          // Highlight Peers Toggle
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: const Text('Highlight Peers'),
                subtitle: const Text('Highlight row, column, and box'),
                value: settings.highlightPeers,
                onChanged: (value) {
                  settings.setHighlightPeers(value);
                },
              );
            },
          ),

           // Show Errors Toggle - Updated onChanged
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: const Text('Show Errors Instantly'),
                value: settings.showErrors,
                onChanged: (value) {
                   // 1. Update the setting state
                   settings.setShowErrors(value);
                   // 2. Trigger immediate board error update in GameProvider
                   if(gameProvider.isPuzzleLoaded) {
                      gameProvider.updateBoardErrors(value);
                      // No need to call gameProvider.notifyListeners() here,
                      // updateBoardErrors handles it internally if errors changed.
                   }
                },
              );
            },
          ),

          // Timer Toggle
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: const Text('Enable Timer'),
                value: settings.timerEnabled,
                onChanged: (value) {
                  settings.setTimerEnabled(value);
                },
              );
            },
          ),

          const SizedBox(height: 20),
          // --- Accessibility Note ---
          Text('Accessibility Note', style: Theme.of(context).textTheme.titleMedium),
          const Text('Consider using "Patterns" or "Numbers" overlay, or the "Accessible Vibrant" palette if you have difficulty distinguishing colors.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
           const SizedBox(height: 20), // Extra space at bottom for scrollability in sheet

        ],
      ),
    );
  }
}