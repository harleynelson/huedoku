// File: lib/screens/game_screen.dart
// Location: ./lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart'; // Import GameProvider for difficulty map
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/bokeh_painter.dart';
import 'package:huedoku/widgets/game_controls.dart';
import 'package:huedoku/widgets/palette_selector_widget.dart';
import 'package:huedoku/widgets/settings_content.dart';
import 'package:huedoku/widgets/sudoku_grid_widget.dart';
import 'package:huedoku/widgets/timer_widget.dart'; // Import TimerWidget (now text-based)
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:huedoku/themes.dart'; // Import themes for theme data access
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _completionDialogShown = false;
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  late AnimationController _bokehAnimationController;
  late Animation<double> _bokehAnimation;

  late ConfettiController _confettiController;

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
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);
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
      // Init Bokeh Animation
      _bokehAnimationController = AnimationController(
         duration: const Duration(seconds: 20),
         vsync: this,
       )..repeat();
       _bokehAnimation = CurvedAnimation( parent: _bokehAnimationController, curve: Curves.linear );
      // Init Confetti
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBokehIfNeeded();
  }

   @override
  void dispose() {
     _bokehAnimationController.dispose();
     _confettiController.dispose();
     super.dispose();
   }

  String _formatDuration(Duration duration) {
      // (Implementation remains the same)
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      if (duration.inHours > 0) { return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds"; }
      else { return "$twoDigitMinutes:$twoDigitSeconds"; }
   }

  void _showCompletionDialog(BuildContext context, Duration finalTime) {
      // (Implementation remains largely the same, using GoogleFonts)
      Timer(const Duration(milliseconds: 150), () {
          if (!mounted || _completionDialogShown) return;
          setState(() { _completionDialogShown = true; });
          _confettiController.play();

          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                  return StatefulBuilder(
                     builder: (context, setStateDialog) {
                        final scoreTicker = TickerProviderDialog(setStateDialog);
                        final scoreAnimController = AnimationController(
                            duration: const Duration(milliseconds: 1200), vsync: scoreTicker );
                        final scoreAnimation = Tween<double>(begin: 0.0, end: finalTime.inSeconds.toDouble()).animate(
                            CurvedAnimation(parent: scoreAnimController, curve: Curves.easeOutCubic)
                        )..addListener(() { setStateDialog((){}); });
                        scoreAnimController.forward();

                         return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            title: Row(
                               children: [
                                 Icon(Icons.celebration_outlined, color: Theme.of(context).colorScheme.primary),
                                 const SizedBox(width: 8),
                                 Text('Congratulations!', style: GoogleFonts.nunito()),
                               ],
                             ),
                            content: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text('You solved the Huedoku in:', style: GoogleFonts.nunito()),
                                 const SizedBox(height: 10),
                                 Text(
                                    _formatDuration(Duration(seconds: scoreAnimation.value.toInt())),
                                    style: GoogleFonts.nunito( // Apply font
                                        textStyle: Theme.of(context).textTheme.headlineSmall,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                         fontFeatures: [const ui.FontFeature.tabularFigures()],
                                    ),
                                 ),
                                  const SizedBox(height: 15),
                               ],
                            ),
                            actions: <Widget>[
                                TextButton(
                                    child: Text('New Game', style: GoogleFonts.nunito()),
                                    onPressed: () {
                                        scoreAnimController.dispose();
                                        Navigator.of(dialogContext).pop();
                                        final game = Provider.of<GameProvider>(context, listen: false);
                                        // When starting new game, re-use last selected difficulty from home? Or default?
                                        // For now, defaults to medium (1) based on GameProvider default
                                        game.loadNewPuzzle();
                                        setState(() { _completionDialogShown = false; _particlesInitialized = false; });
                                    },
                                ),
                                TextButton(
                                  child: Text('Close', style: GoogleFonts.nunito()),
                                  onPressed: () {
                                      scoreAnimController.dispose();
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

  void _showSettingsSheet(BuildContext context) {
       // (Implementation remains the same)
       showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)), ),
          constraints: BoxConstraints( maxHeight: MediaQuery.of(context).size.height * 0.80, ),
          builder: (BuildContext sheetContext) {
             final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
             final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(0.3);
             final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.1);
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              child: BackdropFilter( filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                   decoration: BoxDecoration( color: glassColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)), border: Border(top: BorderSide(color: glassBorder, width: 0.5)), ),
                   child: Padding( padding: const EdgeInsets.only(top: 8.0), child: SettingsContent(), )
                 ),
              ),
            );
          },
        );
   }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // No longer need listen:false version if only used in callbacks
    // final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentTheme = Theme.of(context); // Get theme data

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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
         backgroundColor: currentTheme.brightness == Brightness.dark
             ? Colors.black.withOpacity(0.2)
             : Colors.white.withOpacity(0.1),
         elevation: 0,
         foregroundColor: currentTheme.colorScheme.onSurface,
         // --- AppBar Title Area ---
         title: Text('Huedoku', style: GoogleFonts.nunito()), // Keep title simple
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             Provider.of<GameProvider>(context, listen: false).pauseGame();
             Navigator.pop(context);
           },
         ),
         actions: [
             // --- Display Difficulty ---
             Consumer<GameProvider>( // Listen to GameProvider for difficulty
                builder: (context, game, child) {
                  final difficultyLevel = game.currentPuzzleDifficulty;
                  final difficultyText = difficultyLevel != null
                                        ? difficultyLabels[difficultyLevel] ?? '?' // Get label or '?'
                                        : ''; // Show nothing if null

                  if (difficultyText.isEmpty) {
                      return const SizedBox.shrink(); // Don't show if no difficulty set
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                       label: Text(
                          difficultyText,
                          style: GoogleFonts.nunito(
                            textStyle: currentTheme.textTheme.labelSmall,
                            color: currentTheme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          )
                       ),
                       backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(0.7),
                       padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                       visualDensity: VisualDensity.compact, // Make chip smaller
                       side: BorderSide.none,
                     ),
                  );
                }
             ),

            // --- Pause/Play Button ---
            Selector<GameProvider, Tuple2<bool, bool>>(
               selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
               builder: (context, data, child) {
                   final isPaused = data.item1;
                   final isCompleted = data.item2;

                   if (isCompleted && !_completionDialogShown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                          if(mounted) _showCompletionDialog(context, Provider.of<GameProvider>(context, listen: false).elapsedTime);
                      });
                   }

                   return IconButton(
                     icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null),
                     tooltip: isPaused ? 'Resume' : 'Pause',
                     onPressed: isCompleted ? null : () {
                       final game = Provider.of<GameProvider>(context, listen: false);
                       if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); }
                     },
                   );
               }
            ),
            // Settings Button
            IconButton(
             icon: const Icon(Icons.settings_outlined),
             tooltip: 'Settings',
             onPressed: () { _showSettingsSheet(context); },
            ),
         ],
       ),
      body: Stack(
        children: [
            // Layer 1: Gradient
            Container( decoration: BoxDecoration( gradient: backgroundGradient ) ),
            // Layer 2: Bokeh
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles, animation: _bokehAnimation), size: MediaQuery.of(context).size ),
             // Layer 3: Confetti
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, numberOfParticles: 20, gravity: 0.1, emissionFrequency: 0.03, maxBlastForce: 20, minBlastForce: 8, particleDrag: 0.05, colors: settingsProvider.selectedPalette.colors, createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)), ), ),
            // Layer 4: Main Game Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: <Widget>[
                    // Top Row: Timer
                    Padding(
                       padding: const EdgeInsets.symmetric(vertical: 10.0),
                       child: Consumer<SettingsProvider>(
                         builder: (context, settings, child) {
                           return settings.timerEnabled
                               ? Center(child: TimerWidget()) // Simple text timer now
                               : const SizedBox(height: 50);
                         },
                       ),
                    ),
                    const SizedBox(height: 10),
                    // Grid
                    Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ),
                    const SizedBox(height: 15),
                    // Palette Selector
                    const PaletteSelectorWidget(),
                    const SizedBox(height: 15),
                    // Game Controls
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

// Helper classes (TickerProviderDialog, Tuple2) remain the same
class TickerProviderDialog extends TickerProvider { final StateSetter _setState; TickerProviderDialog(this._setState); @override Ticker createTicker(TickerCallback onTick) => Ticker(onTick, debugLabel: 'DialogTicker'); }
class Tuple2<T1, T2> { final T1 item1; final T2 item2; Tuple2(this.item1, this.item2); @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2; @override int get hashCode => Object.hash(item1, item2); }