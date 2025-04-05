// File: lib/themes.dart
// Location: ./lib/themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

// --- Define Theme Keys ---
// Consistent keys used across SettingsProvider and main.dart
const String lightThemeKey = 'light';
const String darkThemeKey = 'dark';
const String forestThemeKey = 'forest';
const String oceanThemeKey = 'ocean';
const String cosmicThemeKey = 'cosmic';

// --- Common Styling Elements ---
const double _smallRadius = 8.0;
const double _mediumRadius = 16.0;

final _baseInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_smallRadius),
    borderSide: BorderSide.none,
);

// --- Theme Definitions Map ---
final Map<String, ThemeData> appThemes = {
  lightThemeKey: _buildLightTheme(),
  darkThemeKey: _buildDarkTheme(),
  forestThemeKey: _buildForestTheme(),
  oceanThemeKey: _buildOceanTheme(),
  cosmicThemeKey: _buildCosmicTheme(),
  // Add more themes here...
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

ThemeData _buildForestTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.green.shade700, // Forest green seed
        brightness: Brightness.light,
         primary: Colors.green.shade800,
         secondary: Colors.brown.shade400,
         background: const Color(0xFFF1F8E9), // Very light green
         surface: const Color(0xFFE6F0DC),
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.primary.withOpacity(0.6),
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
             titleTextStyle: GoogleFonts.nunito(
               fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onPrimary
            ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondary,
             foregroundColor: colorScheme.onSecondary,
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         cardTheme: CardTheme(
           elevation: 0,
           color: Colors.white.withOpacity(0.4), // Whiter glass for light theme
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.primary.withOpacity(0.05),
             border: _baseInputBorder, enabledBorder: _baseInputBorder, focusedBorder: _baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply(
             bodyColor: colorScheme.onBackground,
             displayColor: colorScheme.onBackground,
         ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
    );
}

 ThemeData _buildOceanTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
     final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.lightBlue.shade400, // Ocean blue seed
        brightness: Brightness.dark,
         primary: Colors.cyan.shade700,
         secondary: Colors.lightBlue.shade300,
         background: const Color(0xFF01579B), // Deep blue
         surface: const Color(0xFF0277BD), // Slightly lighter blue
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.primary.withOpacity(0.6),
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
             titleTextStyle: GoogleFonts.nunito(
               fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onPrimary
            ),
        ),
         floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondary,
             foregroundColor: colorScheme.onSecondary,
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
         ),
         dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         cardTheme: CardTheme(
           elevation: 0,
           color: Colors.black.withOpacity(0.3), // Darker glass for dark theme
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05),
             border: _baseInputBorder, enabledBorder: _baseInputBorder, focusedBorder: _baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply(
             bodyColor: colorScheme.onBackground,
             displayColor: colorScheme.onBackground,
         ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
    );
}


 ThemeData _buildCosmicTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
     final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple.shade400, // Cosmic purple seed
        brightness: Brightness.dark,
         primary: Colors.indigo.shade700,
         secondary: Colors.pinkAccent.shade100,
         background: const Color(0xFF1A1A2E), // Very dark blue/purple
         surface: const Color(0xFF24244A), // Slightly lighter dark blue/purple
         error: Colors.redAccent.shade100,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.primary.withOpacity(0.6),
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
             titleTextStyle: GoogleFonts.nunito( // Or maybe Orbitron for cosmic?
               fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onPrimary
            ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondary,
             foregroundColor: Colors.black, // Need dark text on light pink
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
         ),
         dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         cardTheme: CardTheme(
           elevation: 0,
           color: Colors.black.withOpacity(0.4), // Darker glass
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)),
        ),
         inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05),
             border: _baseInputBorder, enabledBorder: _baseInputBorder, focusedBorder: _baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply(
             bodyColor: colorScheme.onBackground,
             displayColor: colorScheme.onBackground,
         ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
    );
}