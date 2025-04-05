// File: lib/screens/home_screen.dart
// Location: ./lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:huedoku/models/color_palette.dart'; // Import for palette type
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/game_screen.dart';
import 'package:huedoku/screens/settings_screen.dart';
import 'package:huedoku/themes.dart';
import 'package:huedoku/widgets/bokeh_painter.dart'; // Import bokeh
import 'package:provider/provider.dart';
// Import theme definitions to access theme data if needed for gradients etc.
// Although direct access might be better via Theme.of(context)
// import 'package:huedoku/themes.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Add TickerProviderStateMixin for animations
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark; // Store the theme used for last particle generation
  ColorPalette? _lastPaletteUsed; // Store palette for bokeh generation

  // --- Animation Controller for Bokeh ---
  late AnimationController _bokehAnimationController;
  late Animation<double> _bokehAnimation;

  // Function to update/initialize particles safely
  void _updateBokehIfNeeded() {
     if (!mounted) return;

     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     // Check if size is available and valid
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         // If size isn't ready, schedule a check for the next frame
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
         return;
     }
     final currentSize = mediaQueryData.size;
     // Determine dark mode based on the *actual theme data* derived from the key
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette; // Get current palette


     // Conditions to regenerate particles:
     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed; // Check if palette changed

     if (needsUpdate) {
        // Use addPostFrameCallback to avoid calling setState during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
            // Recheck mount status after frame callback
           if (!mounted) return;

           // print("HomeScreen: Updating Bokeh Particles (Init: $_particlesInitialized, Size: $currentSize, DarkMode: $currentThemeIsDark, Palette: ${currentPalette.name})"); // DEBUG

           // Pass current palette and theme info to createBokehParticles
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 15, currentPalette); // Adjust count

           // Update state only if particles actually changed (or first time)
            setState(() {
               _particles = newParticles;
               _particlesInitialized = true;
               _lastScreenSize = currentSize;
               _lastThemeIsDark = currentThemeIsDark;
               _lastPaletteUsed = currentPalette; // Store palette used
            });
        });
     }
  }

  @override
  void initState() {
    super.initState();
    // --- Initialize Bokeh Animation Controller ---
    _bokehAnimationController = AnimationController(
       duration: const Duration(seconds: 25), // Slower animation for home screen
       vsync: this,
     )..repeat(); // Loop the animation
     _bokehAnimation = CurvedAnimation(
       parent: _bokehAnimationController,
       curve: Curves.linear,
     );

    // Initial update check moved to didChangeDependencies
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check if update needed when dependencies (like MediaQuery or Theme) change
    _updateBokehIfNeeded();
  }

  @override
  void dispose() {
      _bokehAnimationController.dispose(); // Dispose animation controller
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen here to trigger build on theme change, which then triggers _updateBokehIfNeeded
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentTheme = Theme.of(context); // Get the current theme data

    // This check runs during build but schedules the actual update/setState post-frame
    _updateBokehIfNeeded();

    // Define Gradients based on the *current theme's* color scheme for better integration
    final Gradient backgroundGradient = LinearGradient(
            colors: [
                currentTheme.colorScheme.surface.withOpacity(0.8), // Use theme surface color
                currentTheme.colorScheme.background, // Use theme background color
                currentTheme.colorScheme.surfaceVariant.withOpacity(0.7), // Use theme surface variant
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      // Scaffold background can be theme background or transparent if gradient covers fully
      // backgroundColor: currentTheme.colorScheme.background,
      body: Stack( // Use Stack for layering background effects
        children: [
          // Layer 1: Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: backgroundGradient, // Use theme-derived gradient
            ),
          ),

          // Layer 2: Animated Bokeh Effect
           if (_particlesInitialized)
             CustomPaint(
                 // Pass the animation value to the painter
                painter: BokehPainter(particles: _particles, animation: _bokehAnimation),
                size: MediaQuery.of(context).size, // Full screen size
             ),


          // Layer 3: Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Huedoku',
                   // Use GoogleFonts helper for consistency and apply theme styles
                  style: GoogleFonts.nunito(
                     textStyle: currentTheme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                         // Use theme color, slightly adjusted if needed
                        color: currentTheme.colorScheme.primary.withOpacity(0.9),
                         shadows: [
                            Shadow(
                                color: currentTheme.colorScheme.shadow.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(1, 2)
                            )
                         ]
                     )
                  ),
                ),
                const SizedBox(height: 60), // More space
                // --- Buttons using Theme styling ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.colorScheme.primaryContainer,
                      foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                      textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), // Apply font
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
                  ),
                  onPressed: () {
                    // Load puzzle (using default difficulty if none selected)
                    gameProvider.loadNewPuzzle();
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
                      // Use secondary or surface color for settings button
                       backgroundColor: currentTheme.colorScheme.secondaryContainer,
                       foregroundColor: currentTheme.colorScheme.onSecondaryContainer,
                       padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                       textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), // Apply font
                       elevation: 3,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
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
        ],
      ),
    );
  }
}