// File: lib/screens/game_screen.dart
// Location: Entire File (Significant changes in build and _showCompletionDialog)

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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Flag to prevent dialog showing multiple times if build triggers rapidly
  bool _completionDialogShown = false;

  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  late AnimationController _bokehAnimationController;
  late Animation<double> _bokehAnimation;
  late ConfettiController _confettiController;

  // --- Methods: initState, didChangeDependencies, dispose, _updateBokehIfNeeded, _formatDuration, _showSettingsSheet ---
  // (These remain unchanged from the previous version)
  @override
  void initState() {
      super.initState();
      _bokehAnimationController = AnimationController( duration: const Duration(seconds: 20), vsync: this, )..repeat();
      _bokehAnimation = CurvedAnimation( parent: _bokehAnimationController, curve: Curves.linear );
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

   @override
  void didChangeDependencies() { super.didChangeDependencies(); _updateBokehIfNeeded(); }

   @override
  void dispose() { _bokehAnimationController.dispose(); _confettiController.dispose(); super.dispose(); }

   void _updateBokehIfNeeded() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded()); return; }
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;
     bool needsUpdate = !_particlesInitialized || currentSize != _lastScreenSize || currentThemeIsDark != _lastThemeIsDark || currentPalette != _lastPaletteUsed;
     if (needsUpdate) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
           if (!mounted) return;
           final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);
            setState(() { _particles = newParticles; _particlesInitialized = true; _lastScreenSize = currentSize; _lastThemeIsDark = currentThemeIsDark; _lastPaletteUsed = currentPalette; });
        }); } }

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


  // --- Updated _showCompletionDialog ---
  void _showCompletionDialog(BuildContext context, Duration finalTime) {
      if (kDebugMode) {
         print("--- Completion Dialog: finalTime = $finalTime ---");
      }

      // Set flag immediately before showing to prevent rapid re-triggering
      // if the build method somehow runs again before the dialog appears.
      setState(() {
        _completionDialogShown = true;
      });
      _confettiController.play(); // Start confetti

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
                      // --- RESTORED "New Game" button ---
                      TextButton(
                          child: Text('New Game', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                          onPressed: () {
                              final game = Provider.of<GameProvider>(context, listen: false);
                              final int difficultyForNewGame = game.initialDifficultySelection ?? 1;

                              // Reset flag *before* popping and loading
                              // Need outer context's setState
                              if (mounted) {
                                  setState(() { _completionDialogShown = false; });
                              }
                              Navigator.of(dialogContext).pop(); // Close the dialog
                              game.loadNewPuzzle(difficulty: difficultyForNewGame);
                          },
                      ),
                      // --- Updated "Close" button ---
                      TextButton(
                        child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                        onPressed: () {
                            // ONLY pop the dialog. Do NOT reset _completionDialogShown here.
                            Navigator.of(dialogContext).pop();
                        },
                      ),
                  ],
              );
          },
      ); // --- No .then() block needed here ---
  }
  // --- End Updated _showCompletionDialog ---


  // --- Updated Build Method ---
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // Listen to GameProvider here for isCompleted state
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);

    _updateBokehIfNeeded();

    final Gradient backgroundGradient = LinearGradient( /* ... gradient colors ... */
            colors: [ currentTheme.colorScheme.surface.withOpacity(0.8), currentTheme.colorScheme.background, currentTheme.colorScheme.surfaceVariant.withOpacity(0.7), ],
            begin: Alignment.topLeft, end: Alignment.bottomRight, );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar( /* ... AppBar remains the same ... */
         backgroundColor: currentTheme.brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.1),
         elevation: 0, foregroundColor: currentTheme.colorScheme.onSurface,
         title: Text('Huedoku', style: GoogleFonts.nunito()),
         leading: IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { gameProvider.pauseGame(); Navigator.pop(context); }, ),
         actions: [
             Consumer<GameProvider>( builder: (context, game, child) { /* ... Difficulty Chip ... */
                  final difficultyLevel = game.currentPuzzleDifficulty;
                  final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : '';
                  if (difficultyText.isEmpty) return const SizedBox.shrink();
                  return Padding( padding: const EdgeInsets.only(right: 8.0),
                    child: Chip( label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ),
                       backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(0.7), padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                       visualDensity: VisualDensity.compact, side: BorderSide.none, ), ); } ),
            Selector<GameProvider, Tuple2<bool, bool>>( selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
               builder: (context, data, child) { /* ... Pause/Play & Dialog Trigger Logic ... */
                   final isPaused = data.item1;
                   final isCompleted = data.item2;
                   if (isCompleted && !_completionDialogShown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                          if(mounted && isCompleted && !_completionDialogShown) {
                              final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime;
                              // Set flag immediately BEFORE showing dialog to prevent races
                              setState(() { _completionDialogShown = true; });
                              _confettiController.play();
                              _showCompletionDialog(context, finalTime);
                              if (kDebugMode) print("--- addPostFrameCallback: _showCompletionDialog called ---");
                          } else if (kDebugMode) { print("--- addPostFrameCallback: skipped (mounted=$mounted, shown=$_completionDialogShown) ---"); }
                      }); }
                   return IconButton( icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null), tooltip: isPaused ? 'Resume' : 'Pause',
                     onPressed: isCompleted ? null : () { final game = Provider.of<GameProvider>(context, listen: false); if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); } }, ); } ),
            IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ),
         ], ),
      body: Stack(
        children: [
            // Layers 1, 2, 3 (Gradient, Bokeh, Confetti) - Unchanged
            Container( decoration: BoxDecoration( gradient: backgroundGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles, animation: _bokehAnimation), size: MediaQuery.of(context).size ),
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, numberOfParticles: 20, gravity: 0.1, emissionFrequency: 0.03, maxBlastForce: 20, minBlastForce: 8, particleDrag: 0.05, colors: settingsProvider.selectedPalette.colors, createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)), ), ),
            // Layer 4: Main Game Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: <Widget>[
                    // Top Row: Timer (unchanged)
                    Padding( padding: const EdgeInsets.symmetric(vertical: 10.0),
                       child: Consumer<SettingsProvider>( builder: (context, settings, child) { return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50); }, ), ),
                    const SizedBox(height: 10),
                    // Grid (unchanged)
                    Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ),
                    const SizedBox(height: 15),

                    // --- Stack for Controls Area ---
                    Stack(
                      alignment: Alignment.center, // Center items in the stack
                      children: [
                        // --- Element 1: Palette + Controls (Visible when NOT completed) ---
                        // This Column defines the space the Stack will occupy.
                        Visibility(
                          visible: !gameProvider.isCompleted,
                          // maintainState/Animation/Size keep it occupying space when invisible
                          maintainState: true,
                          maintainAnimation: true,
                          maintainSize: true,
                          child: Column(
                             mainAxisSize: MainAxisSize.min, // Take only needed vertical space
                             children: const [
                                PaletteSelectorWidget(),
                                SizedBox(height: 15),
                                GameControls(),
                             ],
                          ),
                        ),
                        // --- Element 2: New Game Button (Visible when completed) ---
                        Visibility(
                          visible: gameProvider.isCompleted,
                          child: Padding(
                            // Match vertical padding roughly to center it in the space
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)),
                                style: ElevatedButton.styleFrom( /* ... Button Style ... */
                                    backgroundColor: currentTheme.colorScheme.primaryContainer, foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
                                    elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), ),
                                onPressed: () {
                                  final game = Provider.of<GameProvider>(context, listen: false);
                                  final int difficultyForNewGame = game.initialDifficultySelection ?? 1;
                                  // Reset the dialog shown flag BEFORE loading new puzzle
                                  if (mounted) {
                                      setState(() { _completionDialogShown = false; });
                                  }
                                  game.loadNewPuzzle(difficulty: difficultyForNewGame);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // --- End Stack ---

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