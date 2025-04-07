// File: lib/screens/home_screen.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/game_screen.dart';
import 'package:huedoku/screens/settings_screen.dart';
import 'package:huedoku/widgets/bokeh_painter.dart';
import 'package:provider/provider.dart';
import 'package:huedoku/themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  int _selectedDifficulty = 1; // Default to Medium (key 1)

  // --- ADD Method to Generate Particles Once (Uses constants) ---
  void _generateInitialBokeh() {
     if (!mounted || _particlesInitialized) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);

     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         print("Warning: _generateInitialBokeh called before MediaQuery size is ready.");
         return;
     }
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     // --- UPDATED: Use constant for particle count ---
     final newParticles = createBokehParticles(currentSize, currentThemeIsDark, kBokehParticleCount, currentPalette);

     setState(() {
        _particles = newParticles;
        _particlesInitialized = true;
     });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
       _generateInitialBokeh();
    });
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
      super.dispose();
  }

  // Helper for Difficulty Icons (Unchanged)
  IconData _getDifficultyIcon(int difficultyKey) {
      switch(difficultyKey) {
         case -1: return Icons.casino_outlined; // Random
         case 0: return Icons.cake; // Easy
         case 1: return Icons.beach_access; // Medium
         case 2: return Icons.local_fire_department_outlined; // Hard
         case 3: return Icons.volcano; // Icon for "Pain" (Expert)
         default: return Icons.question_mark;
      }
  }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );

    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8
        ? retroColors.sublist(0, 8)
        : List.generate(8, (_) => currentTheme.colorScheme.primary);

    return Scaffold(
      body: Stack(
        children: [
          Container(
             decoration: BoxDecoration(
                gradient: backgroundGradient ?? defaultFallbackGradient
             )
          ),

           if (_particlesInitialized)
             CustomPaint(
                painter: BokehPainter(particles: _particles),
                size: MediaQuery.of(context).size,
             ),

          Center(
            child: SingleChildScrollView(
              // --- UPDATED: Use constant for padding ---
              padding: const EdgeInsets.symmetric(vertical: kMassiveSpacing),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RichText( textAlign: TextAlign.center,
                     text: TextSpan(
                       // --- UPDATED: Use constants for shadow/opacity ---
                       style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary.withOpacity(kVeryHighOpacity),
                          shadows: [ Shadow( color: currentTheme.colorScheme.shadow.withOpacity(kLowMediumOpacity), blurRadius: 4, offset: const Offset(1, 2) ) ] // Keep specific or make constants
                       ) ),
                       children: <TextSpan>[ TextSpan(text: 'R', style: TextStyle(color: titleColors[1])), TextSpan(text: 'a', style: TextStyle(color: titleColors[2])), TextSpan(text: 'i', style: TextStyle(color: titleColors[0])), TextSpan(text: 'n', style: TextStyle(color: titleColors[3])), TextSpan(text: 'b', style: TextStyle(color: titleColors[4])), TextSpan(text: 'o', style: TextStyle(color: titleColors[5])), TextSpan(text: 'k', style: TextStyle(color: titleColors[6])), TextSpan(text: 'u', style: TextStyle(color: titleColors[7])), ],
                     ),
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kHugeSpacing),
                  Text( "Select Difficulty", style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium) ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kSmallSpacing),
                  Container(
                     // --- UPDATED: Use constant for max width ---
                     constraints: const BoxConstraints(maxWidth: kHomeMaxWidth),
                     width: double.infinity,
                     alignment: Alignment.center,
                    child: Container(
                       // --- UPDATED: Use constant for padding ---
                       margin: const EdgeInsets.symmetric(horizontal: kExtraLargePadding),
                       padding: const EdgeInsets.symmetric(vertical: 5.0), // Keep specific or make constant
                      decoration: BoxDecoration(
                         // --- UPDATED: Use constants for opacity/radius/border ---
                         color: currentTheme.colorScheme.surfaceVariant.withOpacity(kMediumOpacity),
                         borderRadius: BorderRadius.circular(kMediumRadius),
                         border: Border.all(color: currentTheme.colorScheme.outline.withOpacity(kLowMediumOpacity), width: 0.5) // Keep specific or make constant
                      ),
                      child: Column( mainAxisSize: MainAxisSize.min, children: difficultyLabels.entries.map((entry) {
                            final int difficultyKey = entry.key;
                            final String difficultyLabel = entry.value;
                            return RadioListTile<int>(
                               title: Text(difficultyLabel, style: GoogleFonts.nunito()),
                               secondary: Icon( _getDifficultyIcon(difficultyKey), color: _selectedDifficulty == difficultyKey ? currentTheme.colorScheme.primary : currentTheme.colorScheme.onSurfaceVariant, ),
                               value: difficultyKey,
                               groupValue: _selectedDifficulty,
                               onChanged: (int? value) { if (value != null) { setState(() { _selectedDifficulty = value; }); } },
                               activeColor: currentTheme.colorScheme.primary,
                               dense: true,
                               // --- UPDATED: Use constant for padding ---
                               contentPadding: const EdgeInsets.symmetric(horizontal: kLargePadding, vertical: 0),
                            );
                          }).toList(),
                      ),
                    ),
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kHugeSpacing),
                  ElevatedButton.icon(
                     icon: const Icon(Icons.play_arrow),
                     // --- UPDATED: Use constant for font size ---
                     label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: currentTheme.colorScheme.primaryContainer,
                       foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                       // --- UPDATED: Use constants for padding/font/elevation/radius ---
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Keep specific or make constant
                       textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600),
                       elevation: kHighElevation,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                     ),
                    onPressed: () { /* ... New Game Logic ... */
                      final settings = Provider.of<SettingsProvider>(context, listen: false);
                      final game = Provider.of<GameProvider>(context, listen: false);
                      if (_selectedDifficulty == -1) { settings.selectRandomPalette(); game.loadNewPuzzle(difficulty: -1); }
                      else { game.loadNewPuzzle(difficulty: _selectedDifficulty); }
                      Navigator.push( context, MaterialPageRoute(builder: (context) => const GameScreen()), );
                    },
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kExtraLargeSpacing), // Was 25, using constant
                  ElevatedButton.icon(
                     icon: const Icon(Icons.settings_outlined),
                     // --- UPDATED: Use constant for font size ---
                     label: Text('Settings', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: currentTheme.colorScheme.secondaryContainer,
                       foregroundColor: currentTheme.colorScheme.onSecondaryContainer,
                       // --- UPDATED: Use constants for padding/font/elevation/radius ---
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Keep specific or make constant
                       textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600),
                       elevation: kHighElevation,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                     ),
                    onPressed: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const SettingsScreen()), ); },
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