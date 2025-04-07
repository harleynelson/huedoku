// File: lib/screens/home_screen.dart

import 'package:flutter/foundation.dart';
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
import 'package:huedoku/constants.dart';
// --- NEW: Import for Clipboard services ---
import 'package:flutter/services.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  int _selectedDifficulty = 1; // Default to Medium (key 1)

  // Method to Generate Particles Once
  void _generateInitialBokeh() {
     if (!mounted || _particlesInitialized) return;
     // Ensure MediaQuery is available and has size
     final mediaQueryData = MediaQuery.of(context);
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         if (kDebugMode) print("Warning: _generateInitialBokeh called before MediaQuery size is ready. Retrying...");
         // Retry after frame build if size is not ready
         SchedulerBinding.instance.addPostFrameCallback((_) => _generateInitialBokeh());
         return;
     }

     final settings = Provider.of<SettingsProvider>(context, listen: false);
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     // Use the selected palette for Bokeh colors
     final currentPalette = settings.selectedPalette;

     final newParticles = createBokehParticles(currentSize, currentThemeIsDark, kBokehParticleCount, currentPalette);

     // Update state only if mounted
     if (mounted) {
       setState(() {
          _particles = newParticles;
          _particlesInitialized = true;
       });
     }
  }

  @override
  void initState() {
    super.initState();
    // Generate Bokeh after the first frame is built
    SchedulerBinding.instance.addPostFrameCallback((_) {
       _generateInitialBokeh();
    });
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optionally regenerate Bokeh if theme/palette changes while on home screen
    // _generateInitialBokeh(); // Or a more sophisticated update check
  }

  @override
  void dispose() {
      super.dispose();
  }

  // Helper for Difficulty Icons
  IconData _getDifficultyIcon(int difficultyKey) {
      switch(difficultyKey) {
         case -1: return Icons.casino_outlined; // Random
         case 0: return Icons.cake_outlined; // Easy (using outline for consistency)
         case 1: return Icons.beach_access_outlined; // Medium
         case 2: return Icons.local_fire_department_outlined; // Hard
         case 3: return Icons.volcano_outlined; // Painful/Expert
         default: return Icons.question_mark;
      }
  }

  // --- NEW: Method to show the import dialog ---
  void _showImportDialog(BuildContext context) {
     final TextEditingController controller = TextEditingController();
     final gameProvider = Provider.of<GameProvider>(context, listen: false);
     final currentTheme = Theme.of(context); // Get theme data

     showDialog(
        context: context,
        barrierDismissible: false, // User must explicitly cancel or import
        builder: (BuildContext dialogContext) {
           return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
              title: Text('Import Puzzle Code', style: GoogleFonts.nunito()),
              content: TextField(
                 controller: controller,
                 autofocus: true,
                 decoration: InputDecoration(
                    hintText: 'Paste code here (e.g., M:0105...)',
                    // Apply theme defaults for consistency
                    filled: true,
                    fillColor: currentTheme.inputDecorationTheme.fillColor,
                    border: currentTheme.inputDecorationTheme.border,
                    enabledBorder: currentTheme.inputDecorationTheme.enabledBorder,
                    focusedBorder: currentTheme.inputDecorationTheme.focusedBorder,
                    contentPadding: currentTheme.inputDecorationTheme.contentPadding,
                 ),
                 style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.bodyMedium),
                 maxLines: 1, // Single line for the code
                 keyboardType: TextInputType.text, // Standard keyboard
              ),
              actions: <Widget>[
                 TextButton(
                    child: Text('Cancel', style: GoogleFonts.nunito()),
                    onPressed: () {
                       Navigator.of(dialogContext).pop(); // Close the dialog
                    },
                 ),
                 ElevatedButton(
                   child: Text('Import', style: GoogleFonts.nunito()),
                   onPressed: () async {
                      String pastedCode = controller.text.trim(); // Get and trim input
                      if (pastedCode.isNotEmpty) {
                         // Attempt to load the puzzle using the provider method
                         bool success = await gameProvider.loadPuzzleFromString(pastedCode);

                         // IMPORTANT: Close dialog *before* potential navigation or showing SnackBar
                         Navigator.of(dialogContext).pop();

                         if (success && context.mounted) { // Check context validity after async gap
                             // Navigate to game screen on successful import
                             Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GameScreen()),
                             );
                         } else if (context.mounted) {
                            // Show error SnackBar if loading failed
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                  content: const Text('Failed to import puzzle. Check the code format or validity.'),
                                  duration: kSnackbarDuration, // Use constant
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), // Use constant
                                  backgroundColor: Colors.redAccent, // Use a distinct error color
                               ),
                            );
                         }
                      }
                      // If pastedCode is empty, potentially show a message or just do nothing
                   },
                 ),
              ],
           );
        },
     );
  }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false); // Don't need to listen here
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );

    // Safely get title colors
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8
        ? retroColors.sublist(0, 8)
        : List.generate(8, (i) => retroColors.isNotEmpty ? retroColors[i % retroColors.length] : currentTheme.colorScheme.primary);
    final TextStyle baseTitleStyle = GoogleFonts.nunito( textStyle: currentTheme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary.withOpacity(kVeryHighOpacity), // Use constant
                          shadows: [ Shadow( color: currentTheme.colorScheme.shadow.withOpacity(kLowMediumOpacity), blurRadius: 4, offset: const Offset(1, 2) ) ] // Use constants
                       ) ?? const TextStyle()); // Provide a default TextStyle


    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
             decoration: BoxDecoration(
                gradient: backgroundGradient ?? defaultFallbackGradient
             )
          ),
           // Bokeh Painter (if initialized)
           if (_particlesInitialized)
             CustomPaint(
                painter: BokehPainter(particles: _particles),
                size: MediaQuery.of(context).size,
             ),

          // Centered Content
          Center(
            child: SingleChildScrollView( // Allows scrolling on smaller screens
              padding: const EdgeInsets.symmetric(vertical: kMassiveSpacing, horizontal: kDefaultPadding), // Use constants
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Game Title
                  RichText( textAlign: TextAlign.center,
                     text: TextSpan(
                       style: baseTitleStyle,
                       children: <TextSpan>[
                         TextSpan(text: 'R', style: TextStyle(color: titleColors[1 % titleColors.length])),
                         TextSpan(text: 'a', style: TextStyle(color: titleColors[2 % titleColors.length])),
                         TextSpan(text: 'i', style: TextStyle(color: titleColors[0 % titleColors.length])),
                         TextSpan(text: 'n', style: TextStyle(color: titleColors[3 % titleColors.length])),
                         TextSpan(text: 'b', style: TextStyle(color: titleColors[4 % titleColors.length])),
                         TextSpan(text: 'o', style: TextStyle(color: titleColors[5 % titleColors.length])),
                         TextSpan(text: 'k', style: TextStyle(color: titleColors[6 % titleColors.length])),
                         TextSpan(text: 'u', style: TextStyle(color: titleColors[7 % titleColors.length])),
                       ],
                     ),
                  ),
                  const SizedBox(height: kHugeSpacing), // Use constant

                  // Difficulty Selection Section
                  Text( "Select Difficulty", style: GoogleFonts.nunito(textStyle: currentTheme.textTheme.titleMedium) ),
                  const SizedBox(height: kSmallSpacing), // Use constant
                  Container(
                     constraints: const BoxConstraints(maxWidth: kHomeMaxWidth), // Use constant
                     width: double.infinity, // Take constrained width
                     alignment: Alignment.center,
                    child: Container(
                       margin: const EdgeInsets.symmetric(horizontal: 0), // Adjust horizontal margin if needed
                       padding: const EdgeInsets.symmetric(vertical: 5.0), // Keep specific or make constant
                      decoration: BoxDecoration(
                         color: currentTheme.colorScheme.surfaceVariant.withOpacity(kMediumOpacity), // Use constants
                         borderRadius: BorderRadius.circular(kMediumRadius), // Use constant
                         border: Border.all(color: currentTheme.colorScheme.outline.withOpacity(kLowMediumOpacity), width: 0.5) // Use constants
                      ),
                      child: Column( // Use Column for RadioListTiles
                         mainAxisSize: MainAxisSize.min,
                         children: difficultyLabels.entries.map((entry) {
                            final int difficultyKey = entry.key;
                            final String difficultyLabel = entry.value;
                            return RadioListTile<int>(
                               title: Text(difficultyLabel, style: GoogleFonts.nunito()),
                               secondary: Icon( _getDifficultyIcon(difficultyKey), color: _selectedDifficulty == difficultyKey ? currentTheme.colorScheme.primary : currentTheme.colorScheme.onSurfaceVariant, ),
                               value: difficultyKey,
                               groupValue: _selectedDifficulty,
                               onChanged: (int? value) { if (value != null) { setState(() { _selectedDifficulty = value; }); } },
                               activeColor: currentTheme.colorScheme.primary,
                               dense: true, // Make tiles more compact
                               contentPadding: const EdgeInsets.symmetric(horizontal: kLargePadding, vertical: 0), // Use constant
                            );
                          }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: kHugeSpacing), // Use constant

                  // Action Buttons
                  ElevatedButton.icon(
                     icon: const Icon(Icons.play_arrow),
                     label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)), // Use constant
                     style: ElevatedButton.styleFrom(
                       backgroundColor: currentTheme.colorScheme.primaryContainer,
                       foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Use constant for vertical
                       textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600), // Use constant
                       elevation: kHighElevation, // Use constant
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
                     ),
                    onPressed: () {
                      final settings = Provider.of<SettingsProvider>(context, listen: false);
                      final game = Provider.of<GameProvider>(context, listen: false);
                      // Select random palette only if 'Random' difficulty is chosen
                      if (_selectedDifficulty == -1) {
                         settings.selectRandomPalette();
                      }
                      // Load puzzle with selected difficulty
                      game.loadNewPuzzle(difficulty: _selectedDifficulty);
                      // Navigate to the game screen
                      Navigator.push( context, MaterialPageRoute(builder: (context) => const GameScreen()), );
                    },
                  ),
                  const SizedBox(height: kExtraLargeSpacing), // Use constant
                  ElevatedButton.icon(
                     icon: const Icon(Icons.settings_outlined),
                     label: Text('Settings', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)), // Use constant
                     style: ElevatedButton.styleFrom(
                       backgroundColor: currentTheme.colorScheme.secondaryContainer,
                       foregroundColor: currentTheme.colorScheme.onSecondaryContainer,
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Use constant for vertical
                       textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600), // Use constant
                       elevation: kHighElevation, // Use constant
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
                     ),
                    onPressed: () {
                       // Navigate to the settings screen
                       Navigator.push( context, MaterialPageRoute(builder: (context) => const SettingsScreen()), );
                    },
                  ),

                   // --- NEW: Import Puzzle Button ---
                  const SizedBox(height: kExtraLargeSpacing), // Use constant
                  ElevatedButton.icon(
                     icon: const Icon(Icons.content_paste_go_outlined), // Import Icon
                     label: Text('Import Puzzle', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)), // Use constant
                     style: ElevatedButton.styleFrom(
                       // Consistent styling with other buttons
                       backgroundColor: currentTheme.colorScheme.tertiaryContainer, // Use tertiary color
                       foregroundColor: currentTheme.colorScheme.onTertiaryContainer,
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Use constant for vertical
                       textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600), // Use constant
                       elevation: kHighElevation, // Use constant
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
                     ),
                    onPressed: () {
                       _showImportDialog(context); // Call the dialog method
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