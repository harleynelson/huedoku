// File: lib/main.dart
// Location: Entire File (Implementing go_router with query parameters)

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/home_screen.dart';
import 'package:huedoku/screens/game_screen.dart'; // Import GameScreen
import 'package:provider/provider.dart';
// Import the theme definitions
import 'package:huedoku/themes.dart';
// --- Import go_router ---
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode


// --- Define GoRouter Configuration ---
GoRouter _createRouter(BuildContext context) {
 return GoRouter(
   debugLogDiagnostics: kDebugMode,
   routes: [
     GoRoute(
       path: '/',
       builder: (context, state) => const HomeScreen(), // Default route
     ),
     GoRoute(
       path: '/play', // Changed path: No parameter here
       builder: (context, state) {
         // --- Extract the puzzle code from query parameters ---
         final String? puzzleCode = state.uri.queryParameters['code']; // Changed extraction method

         // --- Load Puzzle Logic ---
         if (puzzleCode != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             // Check if context is still mounted before accessing provider
             if (!context.mounted) return;
             final gameProvider = Provider.of<GameProvider>(context, listen: false);
             if (kDebugMode) print("Router attempting to load puzzle from query parameter code: $puzzleCode");
             gameProvider.loadPuzzleFromString(puzzleCode).then((success) {
                if (!success && kDebugMode) {
                  print("Router: Failed to load puzzle from query code: $puzzleCode");
                }
             });
           });
         } else {
            if (kDebugMode) print("Router: 'code' query parameter is null or missing for /play route.");
         }

         // Always return the GameScreen; loading happens asynchronously
         return const GameScreen();
       },
     ),
     // Add other routes here if needed
   ],
   errorBuilder: (context, state) {
      print("GoRouter Error: ${state.error}");
      return Scaffold(
          appBar: AppBar(title: const Text("Routing Error")),
          body: Center(child: Text("Page not found or error: ${state.error}"))
      );
   },
 );
}


void main() {
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash); // Default (supports /#/play?code=...)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.path); // Use this for /play?code=... (requires server config)

  runApp(const HuedokuApp());
}

class HuedokuApp extends StatelessWidget {
  const HuedokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = _createRouter(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final selectedThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
          final ThemeMode currentThemeMode = selectedThemeData.brightness == Brightness.dark
                                             ? ThemeMode.dark
                                             : ThemeMode.light;

          return MaterialApp.router(
            title: 'Rainboku',
            themeMode: currentThemeMode,
            theme: selectedThemeData,
            darkTheme: appThemes[darkThemeKey] ?? selectedThemeData,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}