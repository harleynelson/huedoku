// File: lib/providers/settings_provider.dart
// Location: ./lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // TODO: Import for persistence

// Manages user settings for the game
class SettingsProvider extends ChangeNotifier {
  // --- Default Values ---
  ColorPalette _selectedPalette = ColorPalette.classic;
  CellOverlay _cellOverlay = CellOverlay.none; // Default to none
  bool _highlightPeers = true; // Highlight row/col/box on selection
  bool _showErrors = true; // Immediately show errors
  bool _timerEnabled = true;
  bool _isDarkMode = true; // Default to light mode

  // --- Getters ---
  ColorPalette get selectedPalette => _selectedPalette;
  CellOverlay get cellOverlay => _cellOverlay;
  bool get highlightPeers => _highlightPeers;
  bool get showErrors => _showErrors;
  bool get timerEnabled => _timerEnabled;
  bool get isDarkMode => _isDarkMode;

  // TODO: Implement loading settings from SharedPreferences in constructor or an init method

  // --- Setters with Logging ---

  // Method Changed: SettingsProvider.setSelectedPalette
  Future<void> setSelectedPalette(ColorPalette palette) async {
    // print("[SettingsProvider] setSelectedPalette called with: ${palette.name}. Current: ${_selectedPalette.name}");
    if (_selectedPalette != palette) {
      _selectedPalette = palette;
       // print("[SettingsProvider] Palette changed. Notifying listeners...");
      notifyListeners();
    } else {
        // print("[SettingsProvider] Palette NOT changed. No notification.");
    }
  }

  // Method Changed: SettingsProvider.setCellOverlay
  Future<void> setCellOverlay(CellOverlay overlay) async {
    // print("[SettingsProvider] setCellOverlay called with: $overlay. Current: $_cellOverlay");
    if (_cellOverlay != overlay) {
      _cellOverlay = overlay;
      // print("[SettingsProvider] CellOverlay state changed to: $_cellOverlay. Notifying listeners...");
      notifyListeners();
    } else {
         // print("[SettingsProvider] CellOverlay state NOT changed. No notification.");
    }
  }

  // Method Changed: SettingsProvider.setHighlightPeers
  Future<void> setHighlightPeers(bool value) async {
    // print("[SettingsProvider] setHighlightPeers called with: $value. Current: $_highlightPeers");
    if (_highlightPeers != value) {
      _highlightPeers = value;
      // print("[SettingsProvider] HighlightPeers changed. Notifying listeners...");
      notifyListeners();
    } else {
       // print("[SettingsProvider] HighlightPeers NOT changed. No notification.");
    }
  }

   // Method Changed: SettingsProvider.setShowErrors
   Future<void> setShowErrors(bool value) async {
    // print("[SettingsProvider] setShowErrors called with: $value. Current: $_showErrors");
    if (_showErrors != value) {
      _showErrors = value;
       // print("[SettingsProvider] ShowErrors changed. Notifying listeners...");
      notifyListeners();
    } else {
        // print("[SettingsProvider] ShowErrors NOT changed. No notification.");
    }
  }

  // Method Changed: SettingsProvider.setTimerEnabled
  Future<void> setTimerEnabled(bool value) async {
    // print("[SettingsProvider] setTimerEnabled called with: $value. Current: $_timerEnabled");
    if (_timerEnabled != value) {
      _timerEnabled = value;
      // print("[SettingsProvider] TimerEnabled changed. Notifying listeners...");
      notifyListeners();
    } else {
         // print("[SettingsProvider] TimerEnabled NOT changed. No notification.");
    }
  }

  // Method Changed: SettingsProvider.setIsDarkMode
  Future<void> setIsDarkMode(bool value) async {
    // print("[SettingsProvider] setIsDarkMode called with: $value. Current: $_isDarkMode");
    if (_isDarkMode != value) {
      _isDarkMode = value;
       // print("[SettingsProvider] IsDarkMode changed. Notifying listeners...");
      notifyListeners();
    } else {
        // print("[SettingsProvider] IsDarkMode NOT changed. No notification.");
    }
  }

  /* TODO: Persistence logic using shared_preferences */

}