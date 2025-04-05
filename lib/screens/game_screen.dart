// File: lib/screens/game_screen.dart
// Location: ./lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import SchedulerBinding
import 'package:huedoku/models/color_palette.dart'; // Import needed for palette type
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/bokeh_painter.dart'; // Import bokeh
import 'package:huedoku/widgets/game_controls.dart'; // Import needed for GameControls context
import 'package:huedoku/widgets/palette_selector_widget.dart';
import 'package:huedoku/widgets/settings_content.dart'; // Import the settings content
import 'package:huedoku/widgets/sudoku_grid_widget.dart';
import 'package:huedoku/widgets/timer_widget.dart'; // Import TimerWidget
import 'package:provider/provider.dart';
import 'dart:async'; // Import for Timer
import 'dart:ui' as ui; // Import for ImageFilter (used in controls/palette)
import 'package:confetti/confetti.dart'; // Import Confetti package
import 'dart:math'; // Import for confetti path

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// Add TickerProviderStateMixin for animations
class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _completionDialogShown = false;
  List<BokehParticle> _particles = []; // Bokeh state
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark; // Store theme for bokeh generation
  ColorPalette? _lastPaletteUsed; // Store palette for bokeh generation

  // --- Animation Controller for Bokeh ---
  late AnimationController _bokehAnimationController;
  late Animation<double> _bokehAnimation;

  // --- Confetti Controller ---
  late ConfettiController _confettiController;

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
     final currentPalette = settings.selectedPalette; // Get current palette


     // Conditions to regenerate particles:
     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed; // Check if palette changed

     if (needsUpdate) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
           if (!mounted) return;
            // print("GameScreen: Updating Bokeh Particles (Init: $_particlesInitialized, Size: $currentSize, DarkMode: $currentThemeIsDark, Palette: ${currentPalette.name})"); // DEBUG

           // Pass current palette to createBokehParticles
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);

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
         duration: const Duration(seconds: 20), // Adjust duration for speed
         vsync: this,
       )..repeat(); // Loop the animation
       _bokehAnimation = CurvedAnimation(
         parent: _bokehAnimationController,
         curve: Curves.linear, // Use linear for constant drift/pulse
       );


      // --- Initialize Confetti Controller ---
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));

      // Initial update check moved to didChangeDependencies
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is the correct place for context-dependent initialization
     _updateBokehIfNeeded();
  }

   @override
  void dispose() {
     _bokehAnimationController.dispose(); // Dispose animation controller
     _confettiController.dispose(); // Dispose confetti controller
     super.dispose();
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

  // --- Updated Method: Animated Score Dialog ---
   // Method to show the completion dialog with animated score
  void _showCompletionDialog(BuildContext context, Duration finalTime) {
      Timer(const Duration(milliseconds: 150), () { // Slightly longer delay
          if (!mounted || _completionDialogShown) return;
          setState(() { _completionDialogShown = true; });

          // Play confetti
          _confettiController.play();

          showDialog(
              context: context,
              barrierDismissible: false, // Prevent dismissing by tapping outside
              builder: (BuildContext dialogContext) {
                  // --- Score Animation Setup ---
                  // Use a StatefulWidget for the dialog content to manage animation
                  return StatefulBuilder(
                     builder: (context, setStateDialog) {
                        late AnimationController scoreAnimController;
                        late Animation<double> scoreAnimation;
                        final scoreTicker = TickerProviderDialog(setStateDialog); // Ticker for dialog

                        scoreAnimController = AnimationController(
                            duration: const Duration(milliseconds: 1200), // Duration of score animation
                            vsync: scoreTicker,
                        );
                         scoreAnimation = Tween<double>(begin: 0.0, end: finalTime.inSeconds.toDouble()).animate(
                            CurvedAnimation(parent: scoreAnimController, curve: Curves.easeOutCubic)
                        )..addListener(() {
                            // Update dialog state as animation progresses
                            setStateDialog((){});
                         });

                        // Start the animation when the dialog builds
                        scoreAnimController.forward();

                        // --- Dialog Content ---
                         return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // Rounded dialog
                            title: const Row( // Add icon to title
                               children: [
                                 Icon(Icons.celebration_outlined, color: Colors.amber),
                                 SizedBox(width: 8),
                                 Text('Congratulations!'),
                               ],
                             ),
                            content: Column( // Use Column for layout
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Text('You solved the Huedoku in:'),
                                 const SizedBox(height: 10),
                                 // Animated Score Display
                                 Text(
                                    _formatDuration(Duration(seconds: scoreAnimation.value.toInt())),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                         fontFeatures: [const ui.FontFeature.tabularFigures()],
                                    ),
                                 ),
                                 // Optional: Add a simple visual like animated stars later
                                  const SizedBox(height: 15),
                               ],
                            ),
                            actions: <Widget>[
                                TextButton(
                                    child: const Text('New Game'),
                                    onPressed: () {
                                        scoreAnimController.dispose(); // Dispose animation controller
                                        Navigator.of(dialogContext).pop();
                                        final game = Provider.of<GameProvider>(context, listen: false);
                                        game.loadNewPuzzle();
                                        setState(() {
                                            _completionDialogShown = false;
                                            _particlesInitialized = false; // Force re-init of bokeh
                                        });
                                    },
                                ),
                                TextButton(
                                  child: const Text('Close'),
                                  onPressed: () {
                                      scoreAnimController.dispose(); // Dispose animation controller
                                      Navigator.of(dialogContext).pop();
                                      setState(() { _completionDialogShown = false; });
                                  },
                                ),
                            ],
                        );
                     }
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
      backgroundColor: Colors.transparent, // Make sheet background transparent for glass effect
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80, // Allow more height
      ),
      builder: (BuildContext sheetContext) {
         // Apply glass effect to the sheet content itself
         final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
         final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(0.3);
         final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.1);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
               decoration: BoxDecoration(
                 color: glassColor,
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                 border: Border(top: BorderSide(color: glassBorder, width: 0.5)),
               ),
               // Add padding *inside* the glass container
               child: Padding(
                 padding: const EdgeInsets.only(top: 8.0), // Padding for grab handle area
                 child: SettingsContent(), // Use the settings content
               )
             ),
          ),
        );
      },
    );
   }


  @override
  Widget build(BuildContext context) {
    // Listen for theme changes which affect gradient & bokeh
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false); // Use listen:false for one-off checks if needed

    // Schedule bokeh update check post-build if needed (reacts to size/theme/palette changes)
    _updateBokehIfNeeded();

    // Define Gradients based on theme
    final lightGradient = LinearGradient(
            colors: [Colors.teal[100]!, Colors.lightBlue[200]!, Colors.cyan[50]!], // Added cyan
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
     final darkGradient = LinearGradient(
            colors: [Colors.blueGrey[800]!, Colors.grey[900]!, Colors.indigo[900]!], // Added indigo
             begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      // Make AppBar transparent to see background effects
      backgroundColor: Colors.transparent, // Scaffold background transparent
      extendBodyBehindAppBar: true, // Allow body to go behind app bar
      appBar: AppBar(
         backgroundColor: Theme.of(context).brightness == Brightness.dark
             ? Colors.black.withOpacity(0.2) // Darker transparent AppBar
             : Colors.white.withOpacity(0.1), // Lighter transparent AppBar
         elevation: 0, // No shadow
         foregroundColor: Theme.of(context).colorScheme.onSurface, // Ensure icons/text are visible
         title: const Text('Huedoku Game'),
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             Provider.of<GameProvider>(context, listen: false).pauseGame(); // Pause on back
             Navigator.pop(context);
           },
         ),
         actions: [
            // --- Use Consumer only for parts that *need* to rebuild on game state change ---
            Selector<GameProvider, Tuple2<bool, bool>>( // Select only needed state
               selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
               builder: (context, data, child) {
                   final isPaused = data.item1;
                   final isCompleted = data.item2;

                   // Check for completion within the consumer that watches GameProvider
                   if (isCompleted && !_completionDialogShown) {
                      // Use WidgetsBinding to ensure the dialog is shown after the build phase
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Ensure context is still valid before showing dialog
                          if(mounted) _showCompletionDialog(context, gameProvider.elapsedTime); // Use listen:false version here
                      });
                   }

                   return IconButton(
                     // Disable pause/play button if game is completed
                     icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                               color: isCompleted ? Colors.grey : null),
                     tooltip: isPaused ? 'Resume' : 'Pause',
                     onPressed: isCompleted ? null : () { // Disable if completed
                       // Use listen:false version for actions
                       final game = Provider.of<GameProvider>(context, listen: false);
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

            // Layer 2: Bokeh Effect - Now uses animation controller
            if (_particlesInitialized)
               CustomPaint(
                  // Pass the animation value to the painter
                  painter: BokehPainter(particles: _particles, animation: _bokehAnimation),
                  size: MediaQuery.of(context).size,
               ),

             // Layer 3: Confetti - Aligned to top center
             Align(
               alignment: Alignment.topCenter,
               child: ConfettiWidget(
                 confettiController: _confettiController,
                 blastDirectionality: BlastDirectionality.explosive, // Or directional
                 shouldLoop: false,
                 numberOfParticles: 20, // Adjust particle count
                 gravity: 0.1, // Adjust gravity
                 emissionFrequency: 0.03, // Adjust frequency
                 maxBlastForce: 20, // Adjust force
                 minBlastForce: 8,
                 particleDrag: 0.05,
                  colors: settingsProvider.selectedPalette.colors, // Use palette colors for confetti!
                  // Example path: create simulates falling confetti
                 createParticlePath: (size) {
                    final path = Path();
                    path.addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2));
                    return path;
                 },
               ),
             ),

            // Layer 4: Main Game Content
            SafeArea( // Ensure game content avoids notches/system areas
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Slightly more padding
                child: Column(
                  children: <Widget>[
                    // Top Row: Timer (Now potentially replaced by TimerWidget changes)
                    Padding(
                       padding: const EdgeInsets.symmetric(vertical: 10.0),
                       child: Consumer<SettingsProvider>( // Timer visibility still controlled by consumer
                         builder: (context, settings, child) {
                           return settings.timerEnabled
                               // Use the potentially updated TimerWidget
                               ? const Center(child: TimerWidget())
                               : const SizedBox(height: 50); // Ensure consistent height placeholder
                         },
                       ),
                    ),
                    const SizedBox(height: 10), // Space before grid

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

// Helper class to provide a Ticker for the Dialog animation
class TickerProviderDialog extends TickerProvider {
  final StateSetter _setState;
  TickerProviderDialog(this._setState);

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick, debugLabel: 'DialogTicker');
  }
}

// Simple Tuple class for Selector
class Tuple2<T1, T2> {
    final T1 item1;
    final T2 item2;
    Tuple2(this.item1, this.item2);
     @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2;
    @override int get hashCode => Object.hash(item1, item2);
}