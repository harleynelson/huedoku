// File: lib/themes.dart
// Location: ./lib/themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // Soft cyan/blue to light lavender/pink
        colors: [ Color(0xFFE0F7FA), Color(0xFFE1F5FE), Color(0xFFF3E5F5) ],
        // Changed angle: Top Center to Bottom Center
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme( /* ... appBar style ... */
            backgroundColor: colorScheme.surface.withOpacity(0.5), foregroundColor: colorScheme.onSurface, elevation: 0,
            titleTextStyle: GoogleFonts.nunito( fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onSurface ), ),
         floatingActionButtonTheme: FloatingActionButtonThemeData( /* ... fab style ... */
             backgroundColor: colorScheme.secondaryContainer, foregroundColor: colorScheme.onSecondaryContainer, elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
        dialogTheme: DialogTheme( /* ... dialog style ... */
            backgroundColor: colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
        cardTheme: CardTheme( /* ... card style ... */
           elevation: 0, color: colorScheme.surfaceVariant.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
        inputDecorationTheme: InputDecorationTheme( /* ... input style ... */
             filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: _baseInputBorder, enabledBorder: _baseInputBorder,
             focusedBorder: _baseInputBorder, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( bodyColor: colorScheme.onBackground, displayColor: colorScheme.onBackground, ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
         // --- Add Gradient Extension ---
         extensions: const <ThemeExtension<dynamic>>[
            AppGradients(backgroundGradient: lightGradient),
         ],
    );
}


ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal, // Or change seed if you want different component colors
        brightness: Brightness.dark,
        // Optionally fine-tune scheme colors if needed
        // primary: Colors.teal[300], // Example adjustment
        // background: const Color(0xFF0A0A10), // Example: Very dark background
    );

    // --- Define Darker Gradient ---
    const darkGradient = LinearGradient(
      // Very Dark Blue/Purple -> Dark Blue/Black -> Dark Teal/Green
      colors: [
         Color(0xFF10101F), // Near black with blue/purple tint
         Color(0xFF1A1A2E), // Dark blue/purple (like original Cosmic theme bg)
         Color(0xFF003333), // Very dark teal/green
        ],
      // Keep the angle from previous step, or adjust if desired
      begin: Alignment.topLeft,
      end: Alignment(0.8, 1.0),
    );

    return baseTheme.copyWith(
        colorScheme: colorScheme,
        // You might want to adjust the base scaffold background too for consistency
        // scaffoldBackgroundColor: const Color(0xFF0A0A10), // Example
        scaffoldBackgroundColor: colorScheme.background, // Default scheme background
        appBarTheme: AppBarTheme( /* ... appBar style ... */
            backgroundColor: colorScheme.surface.withOpacity(0.5), foregroundColor: colorScheme.onSurface, elevation: 0,
             titleTextStyle: GoogleFonts.nunito( fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onSurface ), ),
         floatingActionButtonTheme: FloatingActionButtonThemeData( /* ... fab style ... */
             backgroundColor: colorScheme.secondaryContainer, foregroundColor: colorScheme.onSecondaryContainer, elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
        dialogTheme: DialogTheme( /* ... dialog style ... */
            backgroundColor: colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
         cardTheme: CardTheme( /* ... card style ... */
           elevation: 0, color: colorScheme.surfaceVariant.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumRadius)), ),
         inputDecorationTheme: InputDecorationTheme( /* ... input style ... */
             filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: _baseInputBorder, enabledBorder: _baseInputBorder,
             focusedBorder: _baseInputBorder, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme).apply( bodyColor: colorScheme.onBackground, displayColor: colorScheme.onBackground, ),
         visualDensity: VisualDensity.adaptivePlatformDensity,
         // --- Add Gradient Extension ---
          extensions: const <ThemeExtension<dynamic>>[
             AppGradients(backgroundGradient: darkGradient),
          ],
    );
}