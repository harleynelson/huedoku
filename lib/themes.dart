// File: lib/themes.dart
// Location: ./lib/themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

// --- Define Theme Keys ---
// Consistent keys used across SettingsProvider and main.dart
const String lightThemeKey = 'light';
const String darkThemeKey = 'dark';
// --- REMOVED Forest, Ocean, Cosmic keys ---
// const String forestThemeKey = 'forest';
// const String oceanThemeKey = 'ocean';
// const String cosmicThemeKey = 'cosmic';

// --- Common Styling Elements ---
const double _smallRadius = 8.0;
const double _mediumRadius = 16.0;

final _baseInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_smallRadius),
    borderSide: BorderSide.none,
);

// --- Theme Definitions Map ---
// --- REMOVED Forest, Ocean, Cosmic entries ---
final Map<String, ThemeData> appThemes = {
  lightThemeKey: _buildLightTheme(),
  darkThemeKey: _buildDarkTheme(),
  // forestThemeKey: _buildForestTheme(),
  // oceanThemeKey: _buildOceanTheme(),
  // cosmicThemeKey: _buildCosmicTheme(),
};


// --- Private Theme Builder Functions ---

ThemeData _buildLightTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true); // Use Material 3 baseline
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background, // Use scheme colors
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface.withOpacity(0.5), // Semi-transparent
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            titleTextStyle: GoogleFonts.nunito( // Use Google Font
               fontWeight: FontWeight.bold,
               fontSize: 20,
               color: colorScheme.onSurface
            ),
        ),
         floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondaryContainer,
             foregroundColor: colorScheme.onSecondaryContainer,
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
         ),
        dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
        cardTheme: CardTheme(
           elevation: 0,
           color: colorScheme.surfaceVariant.withOpacity(0.5), // For slight glass effect base
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
        inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05),
             border: _baseInputBorder,
             enabledBorder: _baseInputBorder,
             focusedBorder: _baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( // Apply Nunito globally
             bodyColor: colorScheme.onBackground,
             displayColor: colorScheme.onBackground,
         ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
    );
}


ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true); // Use Material 3 baseline
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal, // Same seed, different brightness
        brightness: Brightness.dark,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background, // Dark background
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface.withOpacity(0.5), // Semi-transparent
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
             titleTextStyle: GoogleFonts.nunito( // Use Google Font
               fontWeight: FontWeight.bold,
               fontSize: 20,
               color: colorScheme.onSurface
            ),
        ),
         floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondaryContainer,
             foregroundColor: colorScheme.onSecondaryContainer,
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
         ),
         dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         cardTheme: CardTheme(
           elevation: 0,
           color: colorScheme.surfaceVariant.withOpacity(0.5), // For slight glass effect base
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05),
             border: _baseInputBorder,
             enabledBorder: _baseInputBorder,
             focusedBorder: _baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( // Apply Nunito globally
             bodyColor: colorScheme.onBackground,
             displayColor: colorScheme.onBackground,
         ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
    );
}

// --- REMOVED _buildForestTheme, _buildOceanTheme, _buildCosmicTheme ---
/*
ThemeData _buildForestTheme() { ... }
ThemeData _buildOceanTheme() { ... }
ThemeData _buildCosmicTheme() { ... }
*/