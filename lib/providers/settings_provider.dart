// File: lib/providers/settings_provider.dart
// Location: ./lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
// Import theme keys from your theme definitions file
import 'package:huedoku/themes.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// Manages user settings for the game
class SettingsProvider extends ChangeNotifier {
  // --- Default Values ---
  ColorPalette _selectedPalette = ColorPalette.classic;
  CellOverlay _cellOverlay = CellOverlay.none;
  bool _highlightPeers = true;
  bool _showErrors = true;
  bool _timerEnabled = true;
  // Use system brightness to determine initial default theme key
  String _selectedThemeKey = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
                            ? darkThemeKey
                            : lightThemeKey;

  // Getters
  ColorPalette get selectedPalette => _selectedPalette;
  CellOverlay get cellOverlay => _cellOverlay;
  bool get highlightPeers => _highlightPeers;
  bool get showErrors => _showErrors;
  bool get timerEnabled => _timerEnabled;
  String get selectedThemeKey => _selectedThemeKey;
  // isDarkMode can be derived from the selected theme if needed
  bool get isDarkMode => appThemes[_selectedThemeKey]?.brightness == Brightness.dark;


  // --- Setters ---
  Future<void> setSelectedPalette(ColorPalette palette) async {
    if (_selectedPalette != palette) {
      _selectedPalette = palette;
      notifyListeners();
      // TODO: Save to SharedPreferences
    }
  }

  Future<void> setCellOverlay(CellOverlay overlay) async {
    if (_cellOverlay != overlay) {
      _cellOverlay = overlay;
      notifyListeners();
      // TODO: Save to SharedPreferences
    }
  }

  Future<void> setHighlightPeers(bool value) async {
    if (_highlightPeers != value) {
      _highlightPeers = value;
      notifyListeners();
       // TODO: Save to SharedPreferences
    }
  }

   Future<void> setShowErrors(bool value) async {
    if (_showErrors != value) {
      _showErrors = value;
      notifyListeners();
       // TODO: Save to SharedPreferences
    }
  }

  Future<void> setTimerEnabled(bool value) async {
    if (_timerEnabled != value) {
      _timerEnabled = value;
      notifyListeners();
       // TODO: Save to SharedPreferences
    }
  }

  // --- Setter: Select Theme ---
  Future<void> setSelectedThemeKey(String themeKey) async {
      // Validate theme key exists in our defined themes
      if (!appThemes.containsKey(themeKey)) {
          // Fallback to system default if key is invalid
           themeKey = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
                      ? darkThemeKey
                      : lightThemeKey;
      }

      if (_selectedThemeKey != themeKey) {
          _selectedThemeKey = themeKey;
          notifyListeners();
           // TODO: Save themeKey to SharedPreferences
      }
  }

  /* TODO: Persistence logic using shared_preferences
     Load _selectedThemeKey in loadSettings()
     Save _selectedThemeKey in _saveSettings()
  */
}