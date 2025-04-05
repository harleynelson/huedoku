// File: lib/widgets/timer_widget.dart
// Location: ./lib/widgets/timer_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show FontFeature; // Only needed for FontFeature

// Removed FireParticle class

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

// Removed TickerProviderStateMixin
class _TimerWidgetState extends State<TimerWidget> {
  Timer? _displayTimer;
  late Duration _displayTime;

  // Removed _cometAnimationController
  // Removed _particles list and _random

  // Helper function to format duration (remains the same)
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

  // Timer to update the displayed time text
   void _startDisplayTimer() {
     _displayTimer?.cancel();
    // Update roughly every second is fine for text display
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isPaused && !gameProvider.isCompleted) {
        if (mounted) {
           final providerTime = gameProvider.elapsedTime;
           // Only trigger setState if the seconds actually change
           if (_displayTime.inSeconds != providerTime.inSeconds) {
             setState(() { _displayTime = providerTime; });
           }
        } else { _displayTimer?.cancel(); }
      } else {
         // Sync one last time if paused/completed
         final providerTime = gameProvider.elapsedTime;
         if (mounted && _displayTime.inSeconds != providerTime.inSeconds) {
             setState(() { _displayTime = providerTime; });
         }
         _displayTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _displayTime = gameProvider.elapsedTime;

    // Removed animation controller initialization

    if (!gameProvider.isPaused && !gameProvider.isCompleted) {
      _startDisplayTimer();
    }
  }

  // Removed _updateParticles method

  @override
  void dispose() {
    _displayTimer?.cancel();
    // Removed animation controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to GameProvider to manage the _displayTimer start/stop
    return Consumer<GameProvider>(
       builder: (context, gameProvider, child) {
        final bool shouldTimerRun = !gameProvider.isPaused && !gameProvider.isCompleted;
         // --- Timer Start/Stop Logic ---
         if (shouldTimerRun && !(_displayTimer?.isActive ?? false)) {
             _startDisplayTimer();
         } else if (!shouldTimerRun && (_displayTimer?.isActive ?? false)) {
             _displayTimer?.cancel();
             // Ensure final time is displayed correctly when stopped
             final providerTime = gameProvider.elapsedTime;
             if (_displayTime.inSeconds != providerTime.inSeconds) {
                 // Use WidgetsBinding to avoid setState during build if needed
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _displayTime = providerTime);
                 });
             }
         }
        // --- End Timer Start/Stop Logic ---

        String timeText = _formatDuration(_displayTime);
        final currentTheme = Theme.of(context);

        // --- Build Simple Text Timer UI ---
        return Row(
          mainAxisSize: MainAxisSize.min, // Take only needed space
          children: [
            Text(
              timeText,
              style: currentTheme.textTheme.titleMedium?.copyWith(
                // Use tabular figures for consistent number width
                fontFeatures: [const FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600, // Slightly bolder
                letterSpacing: 0.5, // Add slight letter spacing
                 color: currentTheme.colorScheme.onSurface.withOpacity(0.95),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Removed CometTimerPainter class