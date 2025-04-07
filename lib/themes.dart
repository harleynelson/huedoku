// File: lib/themes.dart
// Location: ./lib/themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huedoku/constants.dart';

// --- Define Theme Keys ---
const String lightThemeKey = 'light';
const String darkThemeKey = 'dark';

// --- Common Styling Elements ---
const double _smallRadius = 8.0;
const double _mediumRadius = 16.0;

final _baseInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_smallRadius),
    borderSide: BorderSide.none,
);

// --- ***** NEW: Define ThemeExtension for Gradients ***** ---
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  const AppGradients({
    required this.backgroundGradient,
  });

  final Gradient? backgroundGradient;

  @override
  AppGradients copyWith({Gradient? backgroundGradient}) {
    return AppGradients(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) {
      return this;
    }
    // Simple lerp just returns one or the other based on t, gradient lerping is complex
    return t < 0.5 ? this : other;
  }

  // Optional: Add custom toString, hashcode, == operator if needed
}
// --- ***** END ThemeExtension Definition ***** ---

// --- Theme Definitions Map ---
final Map<String, ThemeData> appThemes = {
  lightThemeKey: _buildLightTheme(),
  darkThemeKey: _buildDarkTheme(),
};


// --- Private Theme Builder Functions ---

ThemeData _buildLightTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
    );

    // --- Define Light Gradient ---
    const lightGradient = LinearGradient(
        colors: [ Color(0xFFE0F7FA), Color(0xFFE1F5FE), Color(0xFFF3E5F5) ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
    );

    // --- UPDATED: Use Constants for radii and padding ---
    final baseInputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(kSmallRadius), // Use constant
        borderSide: BorderSide.none,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface.withOpacity(kHighMediumOpacity), // Example constant
            foregroundColor: colorScheme.onSurface,
            elevation: 0, // Can be a constant like kZeroElevation if needed
            titleTextStyle: GoogleFonts.nunito( fontWeight: FontWeight.bold, fontSize: kLargeFontSize, color: colorScheme.onSurface ), // Use constant
        ),
         floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondaryContainer,
             foregroundColor: colorScheme.onSecondaryContainer,
             elevation: kDefaultElevation, // Use constant
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
         ),
        dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
        ),
        cardTheme: CardTheme(
           elevation: 0,
           color: colorScheme.surfaceVariant.withOpacity(kHighMediumOpacity), // Example constant
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
        ),
        inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05), // Keep specific value or define constant
             border: baseInputBorder,
             enabledBorder: baseInputBorder,
             focusedBorder: baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: kLargePadding, vertical: kMediumPadding), // Use constants
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( bodyColor: colorScheme.onBackground, displayColor: colorScheme.onBackground, ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
         extensions: const <ThemeExtension<dynamic>>[
            AppGradients(backgroundGradient: lightGradient),
         ],
    );
}


ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
    );

    // --- Define Darker Gradient ---
    const darkGradient = LinearGradient(
      colors: [ Color(0xFF10101F), Color(0xFF1A1A2E), Color(0xFF003333), ],
      begin: Alignment.topLeft,
      end: Alignment(0.8, 1.0), // Keep specific or define constant if reused
    );

    // --- UPDATED: Use Constants for radii and padding ---
     final baseInputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(kSmallRadius), // Use constant
        borderSide: BorderSide.none,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface.withOpacity(kHighMediumOpacity), // Example constant
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            titleTextStyle: GoogleFonts.nunito( fontWeight: FontWeight.bold, fontSize: kLargeFontSize, color: colorScheme.onSurface ), // Use constant
        ),
         floatingActionButtonTheme: FloatingActionButtonThemeData(
             backgroundColor: colorScheme.secondaryContainer,
             foregroundColor: colorScheme.onSecondaryContainer,
             elevation: kDefaultElevation, // Use constant
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
         ),
        dialogTheme: DialogTheme(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
         ),
         cardTheme: CardTheme(
           elevation: 0,
           color: colorScheme.surfaceVariant.withOpacity(kHighMediumOpacity), // Example constant
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
         ),
         inputDecorationTheme: InputDecorationTheme(
             filled: true,
             fillColor: colorScheme.onSurface.withOpacity(0.05),
             border: baseInputBorder,
             enabledBorder: baseInputBorder,
             focusedBorder: baseInputBorder,
             contentPadding: const EdgeInsets.symmetric(horizontal: kLargePadding, vertical: kMediumPadding), // Use constants
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( bodyColor: colorScheme.onBackground, displayColor: colorScheme.onBackground, ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
          extensions: const <ThemeExtension<dynamic>>[
             AppGradients(backgroundGradient: darkGradient),
          ],
    );
}