// File: lib/screens/game_screen.dart
// Location: ./lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/bokeh_painter.dart';
import 'package:huedoku/widgets/game_controls.dart';
import 'package:huedoku/widgets/palette_selector_widget.dart';
import 'package:huedoku/widgets/settings_content.dart';
import 'package:huedoku/widgets/sudoku_grid_widget.dart';
import 'package:huedoku/widgets/timer_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:huedoku/themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> { // Removed TickerProviderStateMixin
  // Flag to prevent dialog showing multiple times if build triggers rapidly
  bool _completionDialogShown = false;

  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  // Removed Bokeh animation controller/animation
  // late AnimationController _bokehAnimationController;
  // late Animation<double> _bokehAnimation;

  // ConfettiController remains
  late ConfettiController _confettiController;

  // --- Methods: initState, didChangeDependencies, dispose, _updateBokehIfNeeded, _formatDuration, _showSettingsSheet, _regenerateBokehParticles ---

  @override
  void initState() {
      super.initState();
      // Init Confetti
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
      // Initial particle generation handled by didChangeDependencies
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will now call _regenerateBokehParticles if needed on first build or theme/palette change
    _updateBokehIfNeeded();
  }

   @override
  void dispose() {
     // Removed Bokeh Animation Dispose
     _confettiController.dispose();
     super.dispose();
   }

   // --- New Method: Regenerate Bokeh Particles ---
  void _regenerateBokehParticles() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     // Ensure screen size is valid before generating
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         // If size isn't ready, try again after the frame renders
         SchedulerBinding.instance.addPostFrameCallback((_) => _regenerateBokehParticles());
         return;
     }
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     // Generate new particles based on current state
     final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);

     // Update state
     setState(() {
        _particles = newParticles;
        _particlesInitialized = true; // Mark as initialized/reinitialized
        // Update tracked state for _updateBokehIfNeeded
        _lastScreenSize = currentSize;
        _lastThemeIsDark = currentThemeIsDark;
        _lastPaletteUsed = currentPalette;
     });
  }
  // --- End New Method ---

  // --- Updated _updateBokehIfNeeded ---
  void _updateBokehIfNeeded() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     // Check if context has size info yet
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
         return;
     }
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;

     // Determine if an update is needed based on tracked state
     bool needsUpdate = !_particlesInitialized ||
                         currentSize != _lastScreenSize ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed;

     if (needsUpdate) {
        // Call the regeneration method if update conditions met
        _regenerateBokehParticles();
     }
  }
  // --- End Updated _updateBokehIfNeeded ---

  String _formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      if (duration.inHours > 0) { return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds"; }
      else { return "$twoDigitMinutes:$twoDigitSeconds"; }
   }

   void _showSettingsSheet(BuildContext context) {
       showModalBottomSheet( context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)), ),
          constraints: BoxConstraints( maxHeight: MediaQuery.of(context).size.height * 0.80, ),
          builder: (BuildContext sheetContext) {
             final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
             final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(0.3);
             final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.1);
            return ClipRRect( borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              child: BackdropFilter( filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container( decoration: BoxDecoration( color: glassColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)), border: Border(top: BorderSide(color: glassBorder, width: 0.5)), ),
                   child: Padding( padding: const EdgeInsets.only(top: 8.0), child: SettingsContent(), ) ), ), ); }, ); }

  // --- Updated _showCompletionDialog (Handles flag logic correctly) ---
  void _showCompletionDialog(BuildContext context, Duration finalTime) {
      if (kDebugMode) {
         print("--- Completion Dialog: finalTime = $finalTime ---");
      }

      // Confetti starts immediately before dialog appears
      _confettiController.play();

      showDialog(
          context: context,
          barrierDismissible: false, // User must interact with buttons
          builder: (BuildContext dialogContext) {
              final ThemeData dialogTheme = Theme.of(dialogContext);
              final TextTheme dialogTextTheme = dialogTheme.textTheme;
              final Color? defaultDialogTextColor = dialogTextTheme.bodyMedium?.color;

              return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  title: Row(
                     children: [
                       Icon(Icons.celebration_outlined, color: dialogTheme.colorScheme.primary),
                       const SizedBox(width: 8),
                       Text('Congratulations!', style: GoogleFonts.nunito(textStyle: dialogTextTheme.titleLarge)),
                     ],
                   ),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                       Text('You solved the Huedoku in:', style: GoogleFonts.nunito(textStyle: dialogTextTheme.bodyMedium)),
                       const SizedBox(height: 10),
                       Text(
                          _formatDuration(finalTime),
                          style: GoogleFonts.nunito(
                             fontSize: dialogTextTheme.headlineSmall!.fontSize! * 1.1,
                             fontWeight: FontWeight.bold,
                             color: defaultDialogTextColor ?? (dialogTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                             fontFeatures: [const ui.FontFeature.tabularFigures()],
                          ),
                          textAlign: TextAlign.center,
                       ),
                        const SizedBox(height: 15),
                      ],
                  ),
                  actions: <Widget>[
                      // "New Game" button resets the flag
                      TextButton(
                          child: Text('New Game', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                          onPressed: () {
                              final game = Provider.of<GameProvider>(context, listen: false);
                              final settings = Provider.of<SettingsProvider>(context, listen: false);
                              final int initialDifficulty = game.initialDifficultySelection ?? 1;
                              if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                              // Reset flag *before* popping and loading
                              if (mounted) { setState(() { _completionDialogShown = false; }); }
                              Navigator.of(dialogContext).pop(); // Close the dialog
                              game.loadNewPuzzle(difficulty: initialDifficulty);
                              _regenerateBokehParticles(); // Regenerate background
                          },
                      ),
                      // "Close" button ONLY pops the dialog
                      TextButton(
                        child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                        onPressed: () {
                            Navigator.of(dialogContext).pop();
                        },
                      ),
                  ],
              );
          },
      );
       // No .then() block needed to reset flag here
  }
  // --- End Updated _showCompletionDialog ---


  // --- Build Method with AppBar Title Update ---
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );

    // Get Retro Palette Colors for title
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 6
        ? retroColors.sublist(0, 6)
        : List.generate(6, (_) => currentTheme.appBarTheme.titleTextStyle?.color ?? currentTheme.colorScheme.primary); // Fallback

    // Get the base style for the AppBar title from the theme
    final TextStyle? baseTitleStyle = currentTheme.appBarTheme.titleTextStyle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
         backgroundColor: currentTheme.brightness == Brightness.dark
             ? Colors.black.withOpacity(0.2)
             : Colors.white.withOpacity(0.1),
         elevation: 0,
         foregroundColor: currentTheme.colorScheme.onSurface, // For back button, etc.

         // --- UPDATED AppBar Title ---
         title: RichText(
            text: TextSpan(
              // Use the AppBar's default title text style as the base
              style: baseTitleStyle,
              children: <TextSpan>[
                TextSpan(text: 'R', style: TextStyle(color: titleColors[0])),
                TextSpan(text: 'a', style: TextStyle(color: titleColors[1])),
                TextSpan(text: 'i', style: TextStyle(color: titleColors[2])),
                TextSpan(text: 'n', style: TextStyle(color: titleColors[3])),
                TextSpan(text: 'b', style: TextStyle(color: titleColors[4])),
                TextSpan(text: 'o', style: TextStyle(color: titleColors[5])),
                // "doku" will inherit the baseTitleStyle color
                const TextSpan(text: 'doku'),
              ],
            ),
          ),
         // --- END UPDATED Title ---

         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             gameProvider.pauseGame(); // Use provider from build start
             Navigator.pop(context);
           },
         ),
         actions: [
             // Difficulty Chip
             Consumer<GameProvider>( builder: (context, game, child) {
                  final difficultyLevel = game.currentPuzzleDifficulty;
                  final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : '';
                  if (difficultyText.isEmpty) return const SizedBox.shrink();
                  return Padding( padding: const EdgeInsets.only(right: 8.0),
                    child: Chip( label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ),
                       backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(0.7), padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                       visualDensity: VisualDensity.compact, side: BorderSide.none, ), ); } ),
            // Pause/Play Button & Dialog Trigger
            Selector<GameProvider, Tuple2<bool, bool>>(
               selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
               builder: (context, data, child) {
                   final isPaused = data.item1;
                   final isCompleted = data.item2;
                   // --- Updated Dialog Trigger Logic ---
                   if (isCompleted && !_completionDialogShown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Double-check condition inside callback
                          if(mounted && isCompleted && !_completionDialogShown) {
                              final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime;
                              // Call dialog FIRST
                              _showCompletionDialog(context, finalTime);
                              // Set flag AFTER calling showDialog
                              // setState(() { _completionDialogShown = true; }); // Let _showCompletionDialog handle this now
                              if (kDebugMode) print("--- addPostFrameCallback: Triggered _showCompletionDialog ---");
                          } else if (kDebugMode) { print("--- addPostFrameCallback: skipped (mounted=$mounted, completed=$isCompleted, shown=$_completionDialogShown) ---"); }
                      });
                   }
                   // Return Pause/Play button
                   return IconButton( icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null), tooltip: isPaused ? 'Resume' : 'Pause',
                     onPressed: isCompleted ? null : () { final game = Provider.of<GameProvider>(context, listen: false); if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); } }, );
               }
            ), // End Selector
            IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ),
         ], ), // End AppBar Actions
      body: Stack(
        children: [
            // Layers 1, 2, 3 (Gradient, Bokeh, Confetti)
            Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles ), size: MediaQuery.of(context).size, ), // No animation
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, numberOfParticles: 20, gravity: 0.1, emissionFrequency: 0.03, maxBlastForce: 20, minBlastForce: 8, particleDrag: 0.05, colors: settingsProvider.selectedPalette.colors, createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)), ), ),
            // Layer 4: Main Game Content
            SafeArea(
              child: Padding( padding: const EdgeInsets.all(12.0),
                child: Column( children: <Widget>[
                    // Top Row: Timer
                    Padding( padding: const EdgeInsets.symmetric(vertical: 10.0), child: Consumer<SettingsProvider>( builder: (context, settings, child) { return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50); }, ), ),
                    const SizedBox(height: 10),
                    // Grid
                    Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ),
                    const SizedBox(height: 15),
                    // Stack for Controls Area
                    Stack( alignment: Alignment.center, children: [
                        // Palette/Controls (when not completed)
                        Visibility( visible: !gameProvider.isCompleted, maintainState: true, maintainAnimation: true, maintainSize: true,
                          child: Column( mainAxisSize: MainAxisSize.min, children: const [ PaletteSelectorWidget(), SizedBox(height: 15), GameControls(), ], ), ),
                        // New Game Button (when completed)
                        Visibility( visible: gameProvider.isCompleted,
                          child: Padding( padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(
                              child: ElevatedButton.icon( icon: const Icon(Icons.refresh), label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)),
                                style: ElevatedButton.styleFrom( backgroundColor: currentTheme.colorScheme.primaryContainer, foregroundColor: currentTheme.colorScheme.onPrimaryContainer, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), ),
                                onPressed: () { // Logic for main screen new game button
                                  final game = Provider.of<GameProvider>(context, listen: false);
                                  final settings = Provider.of<SettingsProvider>(context, listen: false);
                                  final int initialDifficulty = game.initialDifficultySelection ?? 1;
                                  if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                                  // Reset flag FIRST
                                  if (mounted) { setState(() { _completionDialogShown = false; }); }
                                  // THEN load puzzle
                                  game.loadNewPuzzle(difficulty: initialDifficulty);
                                  _regenerateBokehParticles(); // Regenerate background
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Bottom padding
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  // --- End Build Method ---

} // End _GameScreenState

// Helper class Tuple2 (remains unchanged)
class Tuple2<T1, T2> { final T1 item1; final T2 item2; Tuple2(this.item1, this.item2); @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2; @override int get hashCode => Object.hash(item1, item2); }