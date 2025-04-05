// File: lib/main.dart
// Location: ./lib/main.dart

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const HuedokuApp());
}

class HuedokuApp extends StatelessWidget {
  const HuedokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide multiple state objects down the widget tree
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        // Add other providers here if needed (e.g., ThemeProvider)
      ],
      child: Consumer<SettingsProvider>( // Consume SettingsProvider for ThemeMode
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Huedoku',
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.teal, // Example light theme color
              visualDensity: VisualDensity.adaptivePlatformDensity,
              scaffoldBackgroundColor: Colors.grey[100],
               appBarTheme: AppBarTheme(
                 backgroundColor: Colors.teal[300],
                 foregroundColor: Colors.white,
               ),
              // Define other light theme properties
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.teal, // Example dark theme color
              visualDensity: VisualDensity.adaptivePlatformDensity,
              scaffoldBackgroundColor: Colors.grey[900],
               appBarTheme: AppBarTheme(
                 backgroundColor: Colors.teal[800],
                 foregroundColor: Colors.white,
               ),
              // Define other dark theme properties
            ),
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}