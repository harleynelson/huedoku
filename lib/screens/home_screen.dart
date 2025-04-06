// File: lib/screens/home_screen.dart
// Location: ./lib/screens/home_screen.dart
// Modified based on the code you provided

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
import 'dart:math'; // Keep for Random if needed, though createBokehParticles has its own


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for Bokeh particles
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false; // Still useful to know when to draw

  // --- Remove state variables related to checking for updates ---
  // Size? _lastScreenSize;
  // bool? _lastThemeIsDark;
  // ColorPalette? _lastPaletteUsed;

  // Removed Bokeh animation controller if it was here (it was removed previously)

  // ConfettiController is not needed on home screen

  int _selectedDifficulty = 1; // Default to Medium (key 1)

  // --- REMOVED _updateBokehIfNeeded method ---
  /*
  void _updateBokehIfNeeded() { ... } // Remove the entire method
  */

  // --- ADD Method to Generate Particles Once ---
  void _generateInitialBokeh() {
     // Check if already initialized or widget unmounted
     if (!mounted || _particlesInitialized) return;

     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);

     // Ensure screen size is valid before generating
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         // Should not happen in post-frame callback, but safety first
         print("Warning: _generateInitialBokeh called before MediaQuery size is ready.");
         // Optionally schedule a retry:
         // SchedulerBinding.instance.addPostFrameCallback((_) => _generateInitialBokeh());
         return;
     }
     final currentSize = mediaQueryData.size;
     // Use theme data directly from appThemes map for consistency
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     // Generate particles
     final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);

     // Update state
     setState(() {
        _particles = newParticles;
        _particlesInitialized = true;
     });
  }
  // --- End ADD Method ---

  @override
  void initState() {
    super.initState();
    // Remove Bokeh animation init
    // Remove Confetti init
    // --- Generate particles after the first frame ---
    SchedulerBinding.instance.addPostFrameCallback((_) {
       _generateInitialBokeh();
    });
    // --- End Change ---
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // --- REMOVED call to _updateBokehIfNeeded ---
    // If theme/palette changes need to trigger regeneration while this
    // screen is visible but inactive, logic could be added here,
    // but for now, generate only once via initState.
  }

  @override
  void dispose() {
      // Removed Bokeh animation dispose
      // Removed Confetti dispose
      super.dispose();
  }

  // Helper for Difficulty Icons (Unchanged)
  IconData _getDifficultyIcon(int difficultyKey) {
      switch(difficultyKey) {
         case -1: return Icons.casino_outlined; // Random
         case 0: return Icons.cake; // Easy
         case 1: return Icons.beach_access; // Medium
         case 2: return Icons.local_fire_department_outlined; // Hard
         // Ensure this matches the label change in GameProvider if needed
         case 3: return Icons.volcano; // Icon for "Pain" (Expert)
         default: return Icons.question_mark;
      }
  }


  @override
  Widget build(BuildContext context) {
    // Access providers needed in build scope
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

    // --- REMOVED call to _updateBokehIfNeeded from build ---

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Base Gradient - Use theme gradient
          Container(
             decoration: BoxDecoration(
                gradient: backgroundGradient ?? defaultFallbackGradient
             )
          ),

          // Layer 2: Static Bokeh Effect (Draws if initialized)
           if (_particlesInitialized)
             CustomPaint(
                painter: BokehPainter(particles: _particles), // No animation passed
                size: MediaQuery.of(context).size,
             ),

          // Layer 3: Main Content (Structure unchanged)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Title Widget (Unchanged)
                  RichText( textAlign: TextAlign.center, text: TextSpan( style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.displayMedium?.copyWith( fontWeight: FontWeight.bold, color: currentTheme.colorScheme.primary.withOpacity(0.9), shadows: [ Shadow( color: currentTheme.colorScheme.shadow.withOpacity(0.2), blurRadius: 4, offset: const Offset(1, 2) ) ] ) ),
                      children: <TextSpan>[ TextSpan(text: 'R', style: TextStyle(color: titleColors[1])), TextSpan(text: 'a', style: TextStyle(color: titleColors[2])), TextSpan(text: 'i', style: TextStyle(color: titleColors[0])), TextSpan(text: 'n', style: TextStyle(color: titleColors[3])), TextSpan(text: 'b', style: TextStyle(color: titleColors[4])), TextSpan(text: 'o', style: TextStyle(color: titleColors[5])), const TextSpan(text: 'doku'), ], ), ), // Note: Index for 'R' and 'i' were swapped in your code, kept it as is.
                  const SizedBox(height: 30),
                  // Difficulty Selector (Unchanged)
                  Text( "Select Difficulty", style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium) ),
                  const SizedBox(height: 8),
                  Container( constraints: const BoxConstraints(maxWidth: 325), width: double.infinity, alignment: Alignment.center, // Max width was 325 in your code
                    child: Container( margin: const EdgeInsets.symmetric(horizontal: 20.0), padding: const EdgeInsets.symmetric(vertical: 5.0),
                      decoration: BoxDecoration( color: currentTheme.colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12.0), border: Border.all(color: currentTheme.colorScheme.outline.withOpacity(0.2), width: 0.5) ),
                      child: Column( mainAxisSize: MainAxisSize.min, children: difficultyLabels.entries.map((entry) { final int difficultyKey = entry.key; final String difficultyLabel = entry.value;
                            return RadioListTile<int>( title: Text(difficultyLabel, style: GoogleFonts.nunito()), secondary: Icon( _getDifficultyIcon(difficultyKey), color: _selectedDifficulty == difficultyKey ? currentTheme.colorScheme.primary : currentTheme.colorScheme.onSurfaceVariant, ), value: difficultyKey, groupValue: _selectedDifficulty, onChanged: (int? value) { if (value != null) { setState(() { _selectedDifficulty = value; }); } }, activeColor: currentTheme.colorScheme.primary, dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0), ); }).toList(), ), ), ),
                  const SizedBox(height: 30),
                  // Buttons (Unchanged)
                  ElevatedButton.icon( icon: const Icon(Icons.play_arrow), label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)), style: ElevatedButton.styleFrom( backgroundColor: currentTheme.colorScheme.primaryContainer, foregroundColor: currentTheme.colorScheme.onPrimaryContainer, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), ),
                    onPressed: () { final settings = Provider.of<SettingsProvider>(context, listen: false); final game = Provider.of<GameProvider>(context, listen: false); if (_selectedDifficulty == -1) { settings.selectRandomPalette(); game.loadNewPuzzle(difficulty: -1); } else { game.loadNewPuzzle(difficulty: _selectedDifficulty); } Navigator.push( context, MaterialPageRoute(builder: (context) => const GameScreen()), ); }, ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon( icon: const Icon(Icons.settings_outlined), label: Text('Settings', style: GoogleFonts.nunito(fontSize: 18)), style: ElevatedButton.styleFrom( backgroundColor: currentTheme.colorScheme.secondaryContainer, foregroundColor: currentTheme.colorScheme.onSecondaryContainer, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), ),
                    onPressed: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const SettingsScreen()), ); }, ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}