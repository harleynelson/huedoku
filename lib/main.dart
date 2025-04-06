// File: lib/main.dart
// Location: ./lib/main.dart

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/home_screen.dart';
import 'package:provider/provider.dart';
// Import the theme definitions
import 'package:huedoku/themes.dart';

void main() {
  runApp(const HuedokuApp());
}

class HuedokuApp extends StatelessWidget {
  const HuedokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // Add loadSettings() call here if implemented
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: Consumer<SettingsProvider>( // Consume SettingsProvider for Theme selection
        builder: (context, settings, child) {
          // --- Get the selected theme ---
          // Use the theme key from settings, fallback safely
          final selectedThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;

          // Use the brightness from the selected theme data to determine mode
          final ThemeMode currentThemeMode = selectedThemeData.brightness == Brightness.dark
                                             ? ThemeMode.dark
                                             : ThemeMode.light;

          return MaterialApp(
            title: 'Rainbodoku',
            themeMode: currentThemeMode, // Let the selected theme dictate the mode
            // Provide the selected theme as the primary theme
            theme: selectedThemeData,
            // Provide a fallback dark theme if needed, or just use the selected one
            // If selectedThemeData is already dark, this doesn't hurt
            darkTheme: appThemes[darkThemeKey] ?? selectedThemeData,
            // Optionally provide a fallback light theme
            // lightTheme: appThemes[lightThemeKey] ?? selectedThemeData,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}