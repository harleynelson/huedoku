// File: lib/screens/home_screen.dart
// Location: ./lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/screens/game_screen.dart';
import 'package:huedoku/screens/settings_screen.dart';
import 'package:huedoku/widgets/bokeh_painter.dart'; // Import bokeh
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark; // Store the theme used for last particle generation

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
     final currentThemeIsDark = settings.isDarkMode;


     // Conditions to regenerate particles:
     // 1. Not initialized yet.
     // 2. Screen size changed.
     // 3. Theme (dark/light mode) changed since last generation.
     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark;

     if (needsUpdate) {
        // Use addPostFrameCallback to avoid calling setState during build
        // It's generally safer, though less critical now it's outside build.
        SchedulerBinding.instance.addPostFrameCallback((_) {
            // Recheck mount status after frame callback
           if (!mounted) return;

           print("HomeScreen: Updating Bokeh Particles (Init: $_particlesInitialized, Size: $currentSize, DarkMode: $currentThemeIsDark)"); // DEBUG

           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 15); // Adjust count

           // Update state only if particles actually changed (or first time)
            setState(() {
               _particles = newParticles;
               _particlesInitialized = true;
               _lastScreenSize = currentSize;
               _lastThemeIsDark = currentThemeIsDark;
            });
        });
     }
  }

  @override
  void initState() {
    super.initState();
    // --- REMOVED CALL FROM initState ---
    // Initial update check moved to didChangeDependencies
    // _updateBokehIfNeeded();
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check if update needed when dependencies (like MediaQuery) change
    // This is the correct place for context-dependent initialization
    _updateBokehIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    // We need to listen here to trigger build on theme change, which then triggers _updateBokehIfNeeded
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // This check runs during build but schedules the actual update/setState post-frame
    _updateBokehIfNeeded();

    // Define Gradients based on theme
    final lightGradient = LinearGradient(
            colors: [Colors.teal[50]!, Colors.lightBlue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
     final darkGradient = LinearGradient(
            colors: [Colors.grey[850]!, Colors.blueGrey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Stack( // Use Stack for layering background effects
        children: [
          // Layer 1: Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: settingsProvider.isDarkMode ? darkGradient : lightGradient,
            ),
          ),

          // Layer 2: Bokeh Effect
           if (_particlesInitialized)
             CustomPaint(
                // Use a ValueKey to potentially help Flutter optimize repaints
                key: ValueKey(_particles.hashCode),
                size: MediaQuery.of(context).size, // Full screen size
                painter: BokehPainter(particles: _particles),
             ),


          // Layer 3: Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Huedoku',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith( // Adjusted style
                    fontWeight: FontWeight.bold,
                    color: settingsProvider.isDarkMode ? Colors.tealAccent[100] : Colors.teal[900],
                     shadows: [ Shadow(color: Colors.black.withOpacity(0.15), blurRadius: 3, offset: const Offset(1,2))]
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('New Game'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      elevation: 3,
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                   icon: const Icon(Icons.settings),
                   label: const Text('Settings'),
                   style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                       backgroundColor: Colors.grey[600]?.withOpacity(0.8), // Slightly transparent?
                       foregroundColor: Colors.white,
                       elevation: 3,
                   ),
                  onPressed: () {
                     Navigator.push(
                      context,
                      // Navigate to the dedicated SettingsScreen route
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