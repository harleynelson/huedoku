// File: lib/screens/home_screen.dart
// Location: ./lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:huedoku/models/color_palette.dart'; // Import for palette type
import 'package:huedoku/providers/game_provider.dart'; // Import GameProvider for difficulty map
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/game_screen.dart';
import 'package:huedoku/screens/settings_screen.dart';
import 'package:huedoku/widgets/bokeh_painter.dart'; // Import bokeh
import 'package:provider/provider.dart';
import 'package:huedoku/themes.dart'; // Import themes for theme data access
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  late AnimationController _bokehAnimationController;
  late Animation<double> _bokehAnimation;

  // --- State for Difficulty Selection ---
  int _selectedDifficulty = 1; // Default to Medium (key 1)

  void _updateBokehIfNeeded() {
     // (Implementation remains the same)
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
         return;
     }
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed;

     if (needsUpdate) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
           if (!mounted) return;
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 15, currentPalette);
            setState(() {
               _particles = newParticles;
               _particlesInitialized = true;
               _lastScreenSize = currentSize;
               _lastThemeIsDark = currentThemeIsDark;
               _lastPaletteUsed = currentPalette;
            });
        });
     }
  }

  @override
  void initState() {
    super.initState();
    _bokehAnimationController = AnimationController(
       duration: const Duration(seconds: 25),
       vsync: this,
     )..repeat();
     _bokehAnimation = CurvedAnimation(
       parent: _bokehAnimationController,
       curve: Curves.linear,
     );
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBokehIfNeeded();
  }

  @override
  void dispose() {
      _bokehAnimationController.dispose();
      super.dispose();
  }

  // --- Helper for Difficulty Icons ---
  IconData _getDifficultyIcon(int difficultyKey) {
      switch(difficultyKey) {
         case -1: return Icons.casino_outlined; // Random
         case 0: return Icons.cake; // Easy
         case 1: return Icons.beach_access; // Medium
         case 2: return Icons.local_fire_department_outlined; // Hard
         case 3: return Icons.volcano; // Expert
         default: return Icons.question_mark;
      }
  }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentTheme = Theme.of(context);

    _updateBokehIfNeeded();

    final Gradient backgroundGradient = LinearGradient(
            colors: [
                currentTheme.colorScheme.surface.withOpacity(0.8),
                currentTheme.colorScheme.background,
                currentTheme.colorScheme.surfaceVariant.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Base Gradient
          Container( decoration: BoxDecoration( gradient: backgroundGradient ) ),

          // Layer 2: Animated Bokeh Effect
           if (_particlesInitialized)
             CustomPaint(
                painter: BokehPainter(particles: _particles, animation: _bokehAnimation),
                size: MediaQuery.of(context).size,
             ),


          // Layer 3: Main Content
          Center(
            child: SingleChildScrollView( // Allow scrolling if content overflows vertically
              padding: const EdgeInsets.symmetric(vertical: 40.0), // Add padding for scroll
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // --- Title ---
                  Text(
                    'Huedoku',
                     style: GoogleFonts.nunito(
                       textStyle: currentTheme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary.withOpacity(0.9),
                           shadows: [ Shadow( color: currentTheme.colorScheme.shadow.withOpacity(0.2), blurRadius: 4, offset: const Offset(1, 2) ) ]
                       )
                    ),
                  ),
                  const SizedBox(height: 30), // Space before difficulty

                  // --- Vertical Difficulty Selector ---
                  Text(
                     "Select Difficulty",
                      style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium)
                  ),
                  const SizedBox(height: 8),
                  Container(
                     margin: const EdgeInsets.symmetric(horizontal: 40.0),
                     padding: const EdgeInsets.symmetric(vertical: 5.0),
                     decoration: BoxDecoration(
                        color: currentTheme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: currentTheme.colorScheme.outline.withOpacity(0.2), width: 0.5)
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min, // Take minimum height
                       children: difficultyLabels.entries.map((entry) {
                           final int difficultyKey = entry.key;
                           final String difficultyLabel = entry.value;
                           return RadioListTile<int>(
                               title: Text(difficultyLabel, style: GoogleFonts.nunito()),
                               secondary: Icon(
                                  _getDifficultyIcon(difficultyKey),
                                  color: _selectedDifficulty == difficultyKey
                                        ? currentTheme.colorScheme.primary // Highlight selected icon
                                        : currentTheme.colorScheme.onSurfaceVariant,
                               ),
                               value: difficultyKey,
                               groupValue: _selectedDifficulty,
                               onChanged: (int? value) {
                                 if (value != null) {
                                   setState(() {
                                     _selectedDifficulty = value;
                                   });
                                 }
                               },
                               activeColor: currentTheme.colorScheme.primary, // Color of the radio button
                               dense: true, // Reduce vertical height
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                           );
                       }).toList(),
                     ),
                   ),
                   const SizedBox(height: 30), // Space after difficulty


                  // --- Buttons ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: currentTheme.colorScheme.primaryContainer,
                        foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                        textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    onPressed: () {
                      // Pass selected difficulty to provider
                      gameProvider.loadNewPuzzle(difficulty: _selectedDifficulty);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                     icon: const Icon(Icons.settings_outlined),
                     label: Text('Settings', style: GoogleFonts.nunito(fontSize: 18)),
                     style: ElevatedButton.styleFrom(
                         backgroundColor: currentTheme.colorScheme.secondaryContainer,
                         foregroundColor: currentTheme.colorScheme.onSecondaryContainer,
                         padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                         textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
                         elevation: 3,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                     ),
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}