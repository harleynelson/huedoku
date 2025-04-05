// File: lib/screens/game_screen.dart
// Location: ./lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import SchedulerBinding
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/bokeh_painter.dart'; // Import bokeh
import 'package:huedoku/widgets/game_controls.dart'; // Import needed for GameControls context
import 'package:huedoku/widgets/palette_selector_widget.dart';
import 'package:huedoku/widgets/settings_content.dart'; // Import the settings content
import 'package:huedoku/widgets/sudoku_grid_widget.dart';
import 'package:huedoku/widgets/timer_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Import for Timer

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _completionDialogShown = false;
  List<BokehParticle> _particles = []; // Bokeh state
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark; // Store theme for bokeh generation

 // Function to update/initialize particles safely
  void _updateBokehIfNeeded() {
     if (!mounted) return;

     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     // Check if size is available and valid
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
         return;
     }
     final currentSize = mediaQueryData.size;
     final currentThemeIsDark = settings.isDarkMode;


     // Conditions to regenerate particles:
     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark;

     if (needsUpdate) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
           if (!mounted) return;
            print("GameScreen: Updating Bokeh Particles (Init: $_particlesInitialized, Size: $currentSize, DarkMode: $currentThemeIsDark)"); // DEBUG

           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12); // Fewer particles for game screen

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


  // Helper function to format duration for the dialog
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
   }

  // Method to show the completion dialog
   void _showCompletionDialog(BuildContext context, Duration finalTime) {
      Timer(const Duration(milliseconds: 100), () {
           if (!mounted || _completionDialogShown) return;
           setState(() { _completionDialogShown = true; });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
                return AlertDialog(
                    title: const Text('Congratulations!'),
                    content: Text('You solved the Huedoku in ${_formatDuration(finalTime)}!'),
                    actions: <Widget>[
                        TextButton(
                            child: const Text('New Game'),
                            onPressed: () {
                                Navigator.of(dialogContext).pop();
                                final game = Provider.of<GameProvider>(context, listen: false);
                                game.loadNewPuzzle();
                                setState(() {
                                    _completionDialogShown = false;
                                    // --- Force re-init of bokeh on new game ---
                                    _particlesInitialized = false;
                                    // updateBokehIfNeeded will run in the next build cycle
                                    // and regenerate based on current theme/size
                                });
                            },
                        ),
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () {
                              Navigator.of(dialogContext).pop();
                              setState(() { _completionDialogShown = false; });
                          },
                        ),
                    ],
                );
            },
         );
      });
  }

  // Method to show the settings bottom sheet
  void _showSettingsSheet(BuildContext context) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (BuildContext sheetContext) {
        return const SettingsContent();
      },
    );
   }


  @override
  Widget build(BuildContext context) {
    // Listen for theme changes which affect gradient & bokeh
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Schedule bokeh update check post-build if needed (reacts to size/theme changes)
    _updateBokehIfNeeded();

    // Define Gradients based on theme
    final lightGradient = LinearGradient(
            colors: [Colors.teal[100]!, Colors.lightBlue[200]!], // Slightly different game gradient?
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
     final darkGradient = LinearGradient(
            colors: [Colors.blueGrey[800]!, Colors.grey[900]!],
             begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      appBar: AppBar(
         backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.85),
         elevation: 0, // Remove shadow if transparent
        title: const Text('Huedoku Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<GameProvider>(context, listen: false).pauseGame(); // Pause on back
            Navigator.pop(context);
          },
        ),
        actions: [
           Consumer<GameProvider>( // Access game provider for pause/completion state
             builder: (context, game, child) {
               // Check for completion within the consumer that watches GameProvider
               if (game.isCompleted && !_completionDialogShown) {
                  // Use WidgetsBinding to ensure the dialog is shown after the build phase
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Ensure context is still valid before showing dialog
                      if(mounted) _showCompletionDialog(context, game.elapsedTime);
                  });
               }

               return IconButton(
                 // Disable pause/play button if game is completed
                 icon: Icon(game.isPaused ? Icons.play_arrow : Icons.pause,
                           color: game.isCompleted ? Colors.grey : null),
                 tooltip: game.isPaused ? 'Resume' : 'Pause',
                 onPressed: game.isCompleted ? null : () { // Disable if completed
                   if (game.isPaused) {
                     game.resumeGame();
                   } else {
                     game.pauseGame();
                   }
                 },
               );
             }
           ),
           // Settings Button
           IconButton(
             icon: const Icon(Icons.settings_outlined),
             tooltip: 'Settings',
             onPressed: () {
               _showSettingsSheet(context); // Call the method to show the sheet
             },
           ),
        ],
      ),
      body: Stack( // Use Stack for layering background effects
        children: [
            // Layer 1: Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: settingsProvider.isDarkMode ? darkGradient : lightGradient,
              ),
            ),

            // Layer 2: Bokeh Effect - Uses state variable
            if (_particlesInitialized)
               CustomPaint(
                  // Use a ValueKey based on theme + particles to help trigger repaint if needed
                  key: ValueKey("${settingsProvider.isDarkMode}-${_particles.hashCode}"),
                  size: MediaQuery.of(context).size,
                  painter: BokehPainter(particles: _particles),
               ),

            // Layer 3: Main Game Content
            SafeArea( // Ensure game content avoids notches/system areas
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    // Top Row: Timer
                    Padding(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            // Timer visibility still controlled by consumer
                            Consumer<SettingsProvider>(
                             builder: (context, settings, child) {
                               return settings.timerEnabled
                                   ? const TimerWidget()
                                   : const SizedBox(height: 24); // Placeholder space if timer disabled
                             },
                           ),
                         ],
                       ),
                    ),

                    // The Sudoku Grid (Listens to Game and Settings providers internally)
                    Expanded(
                       child: Center(
                         child: AspectRatio(
                           aspectRatio: 1.0,
                           child: SudokuGridWidget(),
                         ),
                       ),
                     ),
                    const SizedBox(height: 15),

                    // Palette Selector (Listens to Game and Settings providers internally)
                    const PaletteSelectorWidget(),
                    const SizedBox(height: 15),

                    // Game Controls (Pass context implicitly)
                    const GameControls(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}