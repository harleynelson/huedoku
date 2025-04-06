// File: lib/providers/settings_provider.dart
// Location: ./lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/themes.dart';
import 'dart:math'; // Import Random

// import 'package:shared_preferences/shared_preferences.dart';

// Manages user settings for the game
class SettingsProvider extends ChangeNotifier {
  // --- Default Values ---
  // --- Changed default palette to Retro ---
  ColorPalette _selectedPalette = ColorPalette.retro;
  CellOverlay _cellOverlay = CellOverlay.none;
  bool _highlightPeers = true;
  bool _showErrors = true;
  bool _timerEnabled = true;
  bool _reduceUsedLocalOptions = false;
  bool _reduceCompleteGlobalOptions = true;

  String _selectedThemeKey = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
                            ? darkThemeKey
                            : lightThemeKey;

  // For random palette selection
  final Random _random = Random();

  // Getters
  ColorPalette get selectedPalette => _selectedPalette;
  CellOverlay get cellOverlay => _cellOverlay;
  bool get highlightPeers => _highlightPeers;
  bool get showErrors => _showErrors;
  bool get timerEnabled => _timerEnabled;
  bool get reduceUsedLocalOptions => _reduceUsedLocalOptions;
  bool get reduceCompleteGlobalOptions => _reduceCompleteGlobalOptions;
  String get selectedThemeKey => _selectedThemeKey;
  bool get isDarkMode => appThemes[_selectedThemeKey]?.brightness == Brightness.dark;


  // --- Setters ---
  Future<void> setSelectedPalette(ColorPalette palette) async {
    if (_selectedPalette != palette) {
      _selectedPalette = palette;
      notifyListeners();
      // TODO: Save to SharedPreferences
    }
  }

  // --- New Method: Select Random Palette ---
  Future<void> selectRandomPalette() async {
     if (ColorPalette.defaultPalettes.isNotEmpty) {
        final currentPaletteIndex = ColorPalette.defaultPalettes.indexOf(_selectedPalette);
        int randomIndex;
        // Ensure the new random palette is different from the current one, if possible
        if (ColorPalette.defaultPalettes.length > 1) {
          do {
            randomIndex = _random.nextInt(ColorPalette.defaultPalettes.length);
          } while (randomIndex == currentPaletteIndex);
        } else {
          randomIndex = 0; // Only one palette exists
        }

        // No need to check if _selectedPalette != newPalette, as random should change it
        _selectedPalette = ColorPalette.defaultPalettes[randomIndex];
        notifyListeners();
        // TODO: Save to SharedPreferences (though maybe don't save if it was random?)
        // Decide if user preference should be overwritten by random selection.
        // For now, we update the provider state, affecting the current game.
     }
  }
  // --- End New Method ---

  Future<void> setCellOverlay(CellOverlay overlay) async {
    if (_cellOverlay != overlay) { _cellOverlay = overlay; notifyListeners(); /* TODO: Save */ }
  }

  Future<void> setHighlightPeers(bool value) async {
    if (_highlightPeers != value) { _highlightPeers = value; notifyListeners(); /* TODO: Save */ }
  }

   Future<void> setShowErrors(bool value) async {
    if (_showErrors != value) { _showErrors = value; notifyListeners(); /* TODO: Save */ }
  }

  Future<void> setTimerEnabled(bool value) async {
    if (_timerEnabled != value) { _timerEnabled = value; notifyListeners(); /* TODO: Save */ }
  }

  Future<void> setReduceUsedLocalOptions(bool value) async {
    if (_reduceUsedLocalOptions != value) { _reduceUsedLocalOptions = value; notifyListeners(); /* TODO: Save */ }
  }

  Future<void> setReduceCompleteGlobalOptions(bool value) async {
    if (_reduceCompleteGlobalOptions != value) { _reduceCompleteGlobalOptions = value; notifyListeners(); /* TODO: Save */ }
  }

  Future<void> setSelectedThemeKey(String themeKey) async {
      if (!appThemes.containsKey(themeKey)) {
           themeKey = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
                      ? darkThemeKey : lightThemeKey; }
      if (_selectedThemeKey != themeKey) { _selectedThemeKey = themeKey; notifyListeners(); /* TODO: Save */ }
  }

  /* TODO: Persistence logic using shared_preferences
     Load/Save settings, including _selectedPalette (maybe save user's explicit choice separately from random overrides?)
  */
}