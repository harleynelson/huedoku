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

   // Helper to get user-friendly names for themes - Updated
   String _themeDescription(String themeKey) {
       switch(themeKey) {
           case lightThemeKey: return 'Light'; // Simplified name
           case darkThemeKey: return 'Dark';  // Simplified name
           // --- REMOVED Forest, Ocean, Cosmic cases ---
           // case forestThemeKey: return 'Forest';
           // case oceanThemeKey: return 'Ocean';
           // case cosmicThemeKey: return 'Cosmic';
           default: return 'Default'; // Fallback
       }
   }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Listen for changes
    final currentTheme = Theme.of(context); // Get current theme for styling

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          // --- Grab Handle ---
           Center( child: Container( width: 40, height: 5, margin: const EdgeInsets.only(bottom: 15.0),
               decoration: BoxDecoration( color: currentTheme.colorScheme.onSurface.withOpacity(0.3), borderRadius: BorderRadius.circular(12), ), ), ),

          Text('Appearance', style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.titleLarge, fontWeight: FontWeight.bold) ),
          const Divider(),

         // --- Theme Selection (Dialog updated implicitly by iterating over smaller appThemes map) ---
          ListTile(
             contentPadding: EdgeInsets.zero,
             title: Text('Theme', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text( _themeDescription(settingsProvider.selectedThemeKey), style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall) ),
             trailing: const Icon(Icons.palette_outlined),
             onTap: () async {
               final selected = await showDialog<String>(
                 context: context,
                 builder: (BuildContext context) {
                   return SimpleDialog(
                     title: Text('Select Theme', style: GoogleFonts.nunito()),
                     // Iterates only over available keys (Light, Dark)
                     children: appThemes.keys.map((themeKey) {
                       return SimpleDialogOption(
                         onPressed: () { Navigator.pop(context, themeKey); },
                         child: Text(_themeDescription(themeKey), style: GoogleFonts.nunito()),
                       );
                     }).toList(),
                   );
                 }
               );
               if (selected != null) {
                 Provider.of<SettingsProvider>(context, listen: false).setSelectedThemeKey(selected);
               }
             },
           ),

          // --- Palette Selection (No changes needed here) ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Color Palette', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            subtitle: Text( settingsProvider.selectedPalette.name, style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall) ),
            trailing: const Icon(Icons.color_lens_outlined),
            onTap: () async { /* ... Palette Dialog Logic (unchanged) ... */
              final selected = await showDialog<ColorPalette>( context: context, builder: (BuildContext context) {
                  return SimpleDialog( title: Text('Select Palette', style: GoogleFonts.nunito()),
                    children: ColorPalette.defaultPalettes.map((palette) {
                      return SimpleDialogOption( onPressed: () { Navigator.pop(context, palette); },
                        child: Row( children: [ Row( children: palette.colors.take(5).map((c) => Container( width: 15, height: 15, color: c, margin: const EdgeInsets.only(right: 2) )).toList(), ),
                            const SizedBox(width: 10), Text(palette.name, style: GoogleFonts.nunito()), ], ), ); }).toList(), ); }, );
              if (selected != null) { Provider.of<SettingsProvider>(context, listen: false).setSelectedPalette(selected); }
            },
          ),
          const SizedBox(height: 15),

          // --- Gameplay Section (Unchanged from previous step) ---
           Text('Gameplay', style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.titleLarge, fontWeight: FontWeight.bold) ),
          const Divider(),
          ListTile( /* ... Cell Content ... */
             contentPadding: EdgeInsets.zero, title: Text('Cell Content', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text( _cellOverlayDescription(settingsProvider.cellOverlay), style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall) ),
             trailing: const Icon(Icons.grid_view),
             onTap: () async { /* ... Cell Overlay Dialog ... */
                final selected = await showDialog<CellOverlay>( context: context, builder: (BuildContext context) {
                    return SimpleDialog( title: Text('Select Cell Content', style: GoogleFonts.nunito()), children: CellOverlay.values.map((overlay) {
                         return SimpleDialogOption( onPressed: () { Navigator.pop(context, overlay); }, child: Text(_cellOverlayDescription(overlay), style: GoogleFonts.nunito()), ); }).toList(), ); } );
                 if (selected != null) { Provider.of<SettingsProvider>(context, listen: false).setCellOverlay(selected); } },
           ),
          SwitchListTile( /* ... Highlight Peers ... */
             contentPadding: EdgeInsets.zero, title: Text('Highlight Peers', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text('Highlight row, column, and box', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)),
             value: settingsProvider.highlightPeers, onChanged: (value) { Provider.of<SettingsProvider>(context, listen: false).setHighlightPeers(value); },
             activeColor: currentTheme.colorScheme.primary, ),
          SwitchListTile( /* ... Show Errors ... */
            contentPadding: EdgeInsets.zero, title: Text('Show Errors Instantly', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            value: settingsProvider.showErrors, activeColor: currentTheme.colorScheme.primary,
            onChanged: (value) { final settings = Provider.of<SettingsProvider>(context, listen: false); settings.setShowErrors(value);
               if(gameProvider.isPuzzleLoaded) { gameProvider.updateBoardErrors(value); } }, ),
          SwitchListTile( /* ... Enable Timer ... */
            contentPadding: EdgeInsets.zero, title: Text('Enable Timer', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
            value: settingsProvider.timerEnabled, activeColor: currentTheme.colorScheme.primary,
            onChanged: (value) { Provider.of<SettingsProvider>(context, listen: false).setTimerEnabled(value); }, ),
          SwitchListTile( /* ... Dim Completed Colors ... */
             contentPadding: EdgeInsets.zero, title: Text('Dim Completed Colors', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text('Fade colors/patterns when all 9 are placed', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)),
             value: settingsProvider.reduceCompleteGlobalOptions, onChanged: (value) { Provider.of<SettingsProvider>(context, listen: false).setReduceCompleteGlobalOptions(value); },
             activeColor: currentTheme.colorScheme.primary, ),
           SwitchListTile( /* ... Dim Used in Row/Col/Block ... */
             contentPadding: EdgeInsets.zero, title: Text('Dim Used in Row/Col/Block', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)),
             subtitle: Text('Fade colors/patterns used in selection area', style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodySmall)),
             value: settingsProvider.reduceUsedLocalOptions, onChanged: (value) { Provider.of<SettingsProvider>(context, listen: false).setReduceUsedLocalOptions(value); },
             activeColor: currentTheme.colorScheme.primary, ),
          const SizedBox(height: 20),

          // --- Accessibility Note (Unchanged) ---
          Text('Accessibility', style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.titleMedium, fontWeight: FontWeight.bold) ),
          Text('Consider using "Patterns" or "Numbers" cell content, or the "Accessible Vibrant" palette if you have difficulty distinguishing colors.',
             style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic), color: currentTheme.colorScheme.onSurface.withOpacity(0.7), ), ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }
}