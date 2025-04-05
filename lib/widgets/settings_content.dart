// File: lib/widgets/settings_content.dart
// Location: ./lib/widgets/settings_content.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:provider/provider.dart';
// Import theme definitions for keys and names
import 'package:huedoku/themes.dart';
import 'package:google_fonts/google_fonts.dart'; // Use font for consistency

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

   // Helper to get user-friendly names for themes
   String _themeDescription(String themeKey) {
       switch(themeKey) {
           case lightThemeKey: return 'Light Default';
           case darkThemeKey: return 'Dark Default';
           case forestThemeKey: return 'Forest';
           case oceanThemeKey: return 'Ocean';
           case cosmicThemeKey: return 'Cosmic';
           default: return 'Default'; // Fallback
       }
   }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Listen for changes
    final currentTheme = Theme.of(context); // Get current theme for styling

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduced vertical padding
      child: ListView(
        shrinkWrap: true, // Important for use in bottom sheet
        children: <Widget>[
          // --- Appearance Section ---
           // Add a grab handle visually indicating the sheet can be pulled
           Center(
             child: Container(
               width: 40,
               height: 5,
               margin: const EdgeInsets.only(bottom: 15.0),
               decoration: BoxDecoration(
                 color: currentTheme.colorScheme.onSurface.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(12),
               ),
             ),
           ),

          Text('Appearance', style: GoogleFonts.nunito( // Use selected font
             textStyle: currentTheme.textTheme.titleLarge,
             fontWeight: FontWeight.bold)
          ),
          const Divider(),

         // --- Theme Selection ---
          ListTile(
             contentPadding: EdgeInsets.zero,
             title: Text('Theme', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text(
                _themeDescription(settingsProvider.selectedThemeKey),
                style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)
             ),
             trailing: const Icon(Icons.palette_outlined),
             onTap: () async {
               final selected = await showDialog<String>(
                 context: context,
                 builder: (BuildContext context) {
                   return SimpleDialog(
                     title: Text('Select Theme', style: GoogleFonts.nunito()),
                     children: appThemes.keys.map((themeKey) { // Iterate over keys from themes.dart
                       return SimpleDialogOption(
                         onPressed: () { Navigator.pop(context, themeKey); },
                         child: Text(_themeDescription(themeKey), style: GoogleFonts.nunito()),
                       );
                     }).toList(),
                   );
                 }
               );
               if (selected != null) {
                  // Use listen:false here as we are only calling a method
                 Provider.of<SettingsProvider>(context, listen: false).setSelectedThemeKey(selected);
               }
             },
           ),


          // Palette Selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Color Palette', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            subtitle: Text(
                settingsProvider.selectedPalette.name,
                 style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)
            ),
            trailing: const Icon(Icons.color_lens_outlined),
            onTap: () async {
              // Show dialog to select palette
              final selected = await showDialog<ColorPalette>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text('Select Palette', style: GoogleFonts.nunito()),
                    children: ColorPalette.defaultPalettes.map((palette) {
                      return SimpleDialogOption(
                        onPressed: () { Navigator.pop(context, palette); },
                        child: Row(
                          children: [
                            // Small preview of the palette
                            Row(
                              children: palette.colors.take(5).map((c) => Container(
                                width: 15, height: 15, color: c, margin: const EdgeInsets.only(right: 2)
                              )).toList(),
                            ),
                            const SizedBox(width: 10),
                            Text(palette.name, style: GoogleFonts.nunito()),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
              if (selected != null) {
                 // Use listen:false here
                Provider.of<SettingsProvider>(context, listen: false).setSelectedPalette(selected);
              }
            },
          ),

          const SizedBox(height: 15),

          // --- Gameplay Section ---
           Text('Gameplay', style: GoogleFonts.nunito(
             textStyle: currentTheme.textTheme.titleLarge,
             fontWeight: FontWeight.bold)
           ),
          const Divider(),

          // Cell Overlay Setting
          ListTile(
             contentPadding: EdgeInsets.zero,
             title: Text('Cell Content', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text(
                _cellOverlayDescription(settingsProvider.cellOverlay),
                 style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)
             ),
             trailing: const Icon(Icons.grid_view), // More relevant icon?
             onTap: () async {
                final selected = await showDialog<CellOverlay>(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                       title: Text('Select Cell Content', style: GoogleFonts.nunito()),
                       children: CellOverlay.values.map((overlay) {
                         return SimpleDialogOption(
                            onPressed: () { Navigator.pop(context, overlay); },
                            child: Text(_cellOverlayDescription(overlay), style: GoogleFonts.nunito()),
                         );
                       }).toList(),
                    );
                  }
                );
                 if (selected != null) {
                   // Use listen:false here
                  Provider.of<SettingsProvider>(context, listen: false).setCellOverlay(selected);
                }
             },
           ),


          // Highlight Peers Toggle
          SwitchListTile(
             contentPadding: EdgeInsets.zero,
             title: Text('Highlight Peers', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text('Highlight row, column, and box', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)),
             value: settingsProvider.highlightPeers,
             onChanged: (value) {
               // Use listen:false here
               Provider.of<SettingsProvider>(context, listen: false).setHighlightPeers(value);
             },
             activeColor: currentTheme.colorScheme.primary,
           ),


          // Show Errors Toggle - Updated onChanged
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Show Errors Instantly', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            value: settingsProvider.showErrors,
             activeColor: currentTheme.colorScheme.primary,
            onChanged: (value) {
               // Use listen:false here
               final settings = Provider.of<SettingsProvider>(context, listen: false);
               settings.setShowErrors(value);
               // Trigger immediate board error update in GameProvider
               if(gameProvider.isPuzzleLoaded) {
                  gameProvider.updateBoardErrors(value);
               }
            },
          ),

          // Timer Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Enable Timer', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            value: settingsProvider.timerEnabled,
             activeColor: currentTheme.colorScheme.primary,
            onChanged: (value) {
               // Use listen:false here
              Provider.of<SettingsProvider>(context, listen: false).setTimerEnabled(value);
            },
          ),

          const SizedBox(height: 20),
          // --- Accessibility Note ---
          Text('Accessibility', style: GoogleFonts.nunito(
             textStyle: currentTheme.textTheme.titleMedium,
             fontWeight: FontWeight.bold)
           ),
          Text('Consider using "Patterns" or "Numbers" cell content, or the "Accessible Vibrant" palette if you have difficulty distinguishing colors.',
             style: GoogleFonts.nunito(
                 textStyle: currentTheme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                 color: currentTheme.colorScheme.onSurface.withOpacity(0.7), // Use theme color
            ),
          ),
           const SizedBox(height: 20), // Extra space at bottom for scrollability in sheet

        ],
      ),
    );
  }
}