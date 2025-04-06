// File: lib/screens/game_screen.dart
// Location: Entire File (Removed Bokeh AnimationController, TickerProviderStateMixin, and related logic)

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

// --- REMOVED TickerProviderStateMixin ---
// (No longer needed as cell animations are self-contained and ConfettiController doesn't require one here)
class _GameScreenState extends State<GameScreen> /* with TickerProviderStateMixin */ {
  bool _completionDialogShown = false;
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;

  // --- REMOVED Bokeh AnimationController ---
  // late AnimationController _bokehAnimationController;
  // late Animation<double> _bokehAnimation;

  // ConfettiController remains
  late ConfettiController _confettiController;

  // --- Methods: _regenerateBokehParticles, _updateBokehIfNeeded ---
  // (These remain unchanged)
  void _regenerateBokehParticles() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _regenerateBokehParticles()); return; }
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;
     final newParticles = createBokehParticles(currentSize, currentThemeIsDark, 12, currentPalette);
     setState(() { _particles = newParticles; _particlesInitialized = true; _lastScreenSize = currentSize; _lastThemeIsDark = currentThemeIsDark; _lastPaletteUsed = currentPalette; }); }

  void _updateBokehIfNeeded() {
     if (!mounted) return;
     final mediaQueryData = MediaQuery.of(context);
     if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
         SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded()); return; }
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     final currentSize = mediaQueryData.size;
     final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
     final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
     final currentPalette = settings.selectedPalette;
     bool needsUpdate = !_particlesInitialized || currentSize != _lastScreenSize || currentThemeIsDark != _lastThemeIsDark || currentPalette != _lastPaletteUsed;
     if (needsUpdate) { _regenerateBokehParticles(); } }


  @override
  void initState() {
      super.initState();
      // --- REMOVED Bokeh Animation Init ---
      // _bokehAnimationController = AnimationController(...)
      // _bokehAnimation = CurvedAnimation(...)

      // Init Confetti
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
      // Initial particle generation handled by didChangeDependencies
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBokehIfNeeded();
  }

   @override
  void dispose() {
      // --- REMOVED Bokeh Animation Dispose ---
      // _bokehAnimationController.dispose();
     _confettiController.dispose();
     super.dispose();
   }

  // --- Methods: _formatDuration, _showSettingsSheet, _showCompletionDialog ---
  // (These remain unchanged)
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
          builder: (BuildContext sheetContext) { /* ... Bottom Sheet Builder ... */
             final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
             final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(0.3);
             final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.1);
            return ClipRRect( borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              child: BackdropFilter( filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container( decoration: BoxDecoration( color: glassColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)), border: Border(top: BorderSide(color: glassBorder, width: 0.5)), ),
                   child: Padding( padding: const EdgeInsets.only(top: 8.0), child: SettingsContent(), ) ), ), ); }, ); }

  void _showCompletionDialog(BuildContext context, Duration finalTime) {
      if (kDebugMode) {
         print("--- Completion Dialog: finalTime = $finalTime ---");
      }

      // --- REMOVED setState from here ---
      // if (mounted) { setState(() { _completionDialogShown = true; }); }
      _confettiController.play(); // Start confetti immediately

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
              // ... (Dialog builder code remains the same) ...
              final ThemeData dialogTheme = Theme.of(dialogContext); final TextTheme dialogTextTheme = dialogTheme.textTheme; final Color? defaultDialogTextColor = dialogTextTheme.bodyMedium?.color;
              return AlertDialog( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  title: Row( children: [ Icon(Icons.celebration_outlined, color: dialogTheme.colorScheme.primary), const SizedBox(width: 8), Text('Congratulations!', style: GoogleFonts.nunito(textStyle: dialogTextTheme.titleLarge)), ], ),
                  content: Column( mainAxisSize: MainAxisSize.min, children: [ Text('You solved the Huedoku in:', style: GoogleFonts.nunito(textStyle: dialogTextTheme.bodyMedium)), const SizedBox(height: 10),
                       Text( _formatDuration(finalTime), style: GoogleFonts.nunito( fontSize: dialogTextTheme.headlineSmall!.fontSize! * 1.1, fontWeight: FontWeight.bold, color: defaultDialogTextColor ?? (dialogTheme.brightness == Brightness.dark ? Colors.white : Colors.black), fontFeatures: [const ui.FontFeature.tabularFigures()], ), textAlign: TextAlign.center, ),
                        const SizedBox(height: 15), ], ),
                  actions: <Widget>[
                      TextButton( child: Text('New Game', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                          onPressed: () {
                              final game = Provider.of<GameProvider>(context, listen: false); final settings = Provider.of<SettingsProvider>(context, listen: false); final int initialDifficulty = game.initialDifficultySelection ?? 1;
                              if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                              // Reset flag *before* popping and loading
                              if (mounted) { setState(() { _completionDialogShown = false; }); } // This reset is correct
                              Navigator.of(dialogContext).pop(); // Close the dialog
                              game.loadNewPuzzle(difficulty: initialDifficulty);
                              _regenerateBokehParticles();
                          }, ),
                      TextButton( child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                        onPressed: () {
                            // ONLY pop the dialog. Do NOT reset _completionDialogShown here.
                            Navigator.of(dialogContext).pop();
                        }, ), ], ); }, );
       // --- REMOVED .then() block ---
  }


  @override
  Widget build(BuildContext context) {
    // ... (Provider setup, theme, gradient logic - unchanged) ...
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );

    return Scaffold(
      // ... (Scaffold setup, AppBar - unchanged) ...
      backgroundColor: Colors.transparent, extendBodyBehindAppBar: true,
      appBar: AppBar( /* ... AppBar Content ... */
           backgroundColor: currentTheme.brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.1), elevation: 0, foregroundColor: currentTheme.colorScheme.onSurface,
           title: Text('Huedoku', style: GoogleFonts.nunito()), leading: IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { gameProvider.pauseGame(); Navigator.pop(context); }, ),
           actions: [ /* ... Difficulty Chip ... */ Consumer<GameProvider>( builder: (context, game, child) { final difficultyLevel = game.currentPuzzleDifficulty; final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : ''; if (difficultyText.isEmpty) return const SizedBox.shrink(); return Padding( padding: const EdgeInsets.only(right: 8.0), child: Chip( label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ), backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(0.7), padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), visualDensity: VisualDensity.compact, side: BorderSide.none, ), ); } ),
              // --- Updated Selector Builder ---
              Selector<GameProvider, Tuple2<bool, bool>>(
                 selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
                 builder: (context, data, child) {
                     final isPaused = data.item1;
                     final isCompleted = data.item2;
                     // Check condition before scheduling callback
                     if (isCompleted && !_completionDialogShown) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Double-check condition inside callback
                            if(mounted && isCompleted && !_completionDialogShown) {
                                final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime;
                                // Show the dialog FIRST
                                _showCompletionDialog(context, finalTime);
                                // Set the flag AFTER initiating showDialog
                                setState(() { _completionDialogShown = true; }); // Moved setState here!
                                if (kDebugMode) print("--- addPostFrameCallback: Dialog shown, flag set true ---");
                            } else if (kDebugMode) { print("--- addPostFrameCallback: skipped (mounted=$mounted, completed=$isCompleted, shown=$_completionDialogShown) ---"); }
                        });
                     }
                     // Return Pause/Play button (unchanged)
                     return IconButton( icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null), tooltip: isPaused ? 'Resume' : 'Pause',
                       onPressed: isCompleted ? null : () { final game = Provider.of<GameProvider>(context, listen: false); if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); } }, );
                 }
              ), // End Selector
              IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ),
           ], ), // End AppBar Actions
      // ... (Body: Stack, Background, Bokeh, Confetti, SafeArea, Column, Timer, Grid, Stack for Controls/NewGame - unchanged) ...
      body: Stack( children: [ Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles ), size: MediaQuery.of(context).size, ), // No animation
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, numberOfParticles: 20, gravity: 0.1, emissionFrequency: 0.03, maxBlastForce: 20, minBlastForce: 8, particleDrag: 0.05, colors: settingsProvider.selectedPalette.colors, createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)), ), ),
            SafeArea( child: Padding( padding: const EdgeInsets.all(12.0),
                child: Column( children: <Widget>[ Padding( padding: const EdgeInsets.symmetric(vertical: 10.0), child: Consumer<SettingsProvider>( builder: (context, settings, child) { return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50); }, ), ), const SizedBox(height: 10),
                    Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ), const SizedBox(height: 15),
                    Stack( alignment: Alignment.center, children: [ Visibility( visible: !gameProvider.isCompleted, maintainState: true, maintainAnimation: true, maintainSize: true, child: Column( mainAxisSize: MainAxisSize.min, children: const [ PaletteSelectorWidget(), SizedBox(height: 15), GameControls(), ], ), ),
                        Visibility( visible: gameProvider.isCompleted, child: Padding( padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(
                              child: ElevatedButton.icon( icon: const Icon(Icons.refresh), label: Text('New Game', style: GoogleFonts.nunito(fontSize: 18)),
                                style: ElevatedButton.styleFrom( backgroundColor: currentTheme.colorScheme.primaryContainer, foregroundColor: currentTheme.colorScheme.onPrimaryContainer, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), ),
                                onPressed: () { final game = Provider.of<GameProvider>(context, listen: false); final settings = Provider.of<SettingsProvider>(context, listen: false); final int initialDifficulty = game.initialDifficultySelection ?? 1; if (initialDifficulty == -1) { settings.selectRandomPalette(); } if (mounted) { setState(() { _completionDialogShown = false; }); } game.loadNewPuzzle(difficulty: initialDifficulty); _regenerateBokehParticles(); }, ), ), ), ), ], ),
                    const SizedBox(height: 10), ], ), ), ), ], ), ); }

} //State

// Helper class Tuple2 (remains unchanged)
class Tuple2<T1, T2> { final T1 item1; final T2 item2; Tuple2(this.item1, this.item2); @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2; @override int get hashCode => Object.hash(item1, item2); }