// File: lib/screens/home_screen.dart
// Location: ./lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:huedoku/models/color_palette.dart'; // Import for palette type & direct access
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

class _HomeScreenState extends State<HomeScreen> { // Removed TickerProviderStateMixin
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  // Removed Bokeh animation controller/animation
  // late AnimationController _bokehAnimationController;
  // late Animation<double> _bokehAnimation;

  // ConfettiController is not needed on home screen
  // late ConfettiController _confettiController;

  int _selectedDifficulty = 1; // Default to Medium (key 1)

  void _updateBokehIfNeeded() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     // Ensure screen size is valid before generating
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
         return;
     }
     final currentSize = mediaQueryData.size;
     // Use theme data directly from appThemes map for consistency
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed;

     if (needsUpdate) {
        // Use addPostFrameCallback to ensure setState happens after build if needed
        SchedulerBinding.instance.addPostFrameCallback((_) {
           if (!mounted) return;
           // Generate new particles based on current state
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette); // Reduced count slightly
            // Update state
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
    // Removed Bokeh animation init
    // Removed Confetti init (not needed here)
    // Initial particle generation triggered by didChangeDependencies
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensures Bokeh updates if theme/palette changes while screen is inactive
    _updateBokehIfNeeded();
  }

  @override
  void dispose() {
      // Removed Bokeh animation dispose
      // Removed Confetti dispose
      super.dispose();
  }

  // Helper for Difficulty Icons
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
    // Get Gradient from Theme Extension
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    // Provide a fallback just in case the extension is missing
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );

    // Get Retro Palette Colors for title
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 6
        ? retroColors.sublist(0, 6) // Use first 6 colors
        : List.generate(6, (_) => currentTheme.colorScheme.primary); // Fallback

    // Call this in build to ensure particles update if dependencies change
    _updateBokehIfNeeded();

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Base Gradient - Use theme gradient
          Container(
             decoration: BoxDecoration(
                gradient: backgroundGradient ?? defaultFallbackGradient
             )
          ),

          // Layer 2: Static Bokeh Effect
           if (_particlesInitialized)
             CustomPaint(
                painter: BokehPainter(particles: _particles), // No animation passed
                size: MediaQuery.of(context).size,
             ),

          // Layer 3: Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // --- UPDATED Title Widget ---
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        textStyle: currentTheme.textTheme.displayMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: currentTheme.colorScheme.primary.withOpacity(0.9),
                           shadows: [ Shadow( color: currentTheme.colorScheme.shadow.withOpacity(0.2), blurRadius: 4, offset: const Offset(1, 2) ) ]
                        )
                      ),
                      children: <TextSpan>[
                        TextSpan(text: 'R', style: TextStyle(color: titleColors[1])),
                        TextSpan(text: 'a', style: TextStyle(color: titleColors[2])),
                        TextSpan(text: 'i', style: TextStyle(color: titleColors[0])),
                        TextSpan(text: 'n', style: TextStyle(color: titleColors[3])),
                        TextSpan(text: 'b', style: TextStyle(color: titleColors[4])),
                        TextSpan(text: 'o', style: TextStyle(color: titleColors[5])),
                        const TextSpan(text: 'doku'), // Inherits base style
                      ],
                    ),
                  ),
                  // --- END UPDATED Title Widget ---

                  const SizedBox(height: 30),
                  Text( "Select Difficulty", style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium) ),
                  const SizedBox(height: 8),

                  // --- Outer Container with Max Width Constraint ---
                  Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Container( // Original Container for styling
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      decoration: BoxDecoration(
                         color: currentTheme.colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12.0), border: Border.all(color: currentTheme.colorScheme.outline.withOpacity(0.2), width: 0.5)
                      ),
                      child: Column( // Column with RadioListTiles
                        mainAxisSize: MainAxisSize.min,
                        children: difficultyLabels.entries.map((entry) {
                            final int difficultyKey = entry.key; final String difficultyLabel = entry.value;
                            return RadioListTile<int>(
                                title: Text(difficultyLabel, style: GoogleFonts.nunito()),
                                secondary: Icon( _getDifficultyIcon(difficultyKey), color: _selectedDifficulty == difficultyKey ? currentTheme.colorScheme.primary : currentTheme.colorScheme.onSurfaceVariant, ),
                                value: difficultyKey,
                                groupValue: _selectedDifficulty,
                                onChanged: (int? value) { if (value != null) { setState(() { _selectedDifficulty = value; }); } },
                                activeColor: currentTheme.colorScheme.primary,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                           );
                        }).toList(),
                      ),
                    ),
                  ),
                  // --- End Outer Container ---

                   const SizedBox(height: 30),

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
                      final settings = Provider.of<SettingsProvider>(context, listen: false);
                      final game = Provider.of<GameProvider>(context, listen: false);
                      // Random palette selection if difficulty is Random
                      if (_selectedDifficulty == -1) {
                         settings.selectRandomPalette();
                         game.loadNewPuzzle(difficulty: -1);
                      } else {
                         game.loadNewPuzzle(difficulty: _selectedDifficulty);
                      }
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