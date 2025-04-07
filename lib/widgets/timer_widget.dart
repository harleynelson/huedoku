// File: lib/widgets/timer_widget.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show FontFeature;
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _displayTimer;
  late Duration _displayTime;

  // Helper function to format duration (Unchanged)
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

  // Timer to update the displayed time text (Uses constant)
   void _startDisplayTimer() {
     _displayTimer?.cancel();
    // --- UPDATED: Use constant for interval ---
    _displayTimer = Timer.periodic(kTimerUpdateInterval, (_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isPaused && !gameProvider.isCompleted) {
        if (mounted) {
           final providerTime = gameProvider.elapsedTime;
           if (_displayTime.inSeconds != providerTime.inSeconds) {
             setState(() { _displayTime = providerTime; });
           }
        } else { _displayTimer?.cancel(); }
      } else {
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

    if (!gameProvider.isPaused && !gameProvider.isCompleted) {
      _startDisplayTimer();
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
       builder: (context, gameProvider, child) {
        final bool shouldTimerRun = !gameProvider.isPaused && !gameProvider.isCompleted;
         if (shouldTimerRun && !(_displayTimer?.isActive ?? false)) {
             _startDisplayTimer();
         } else if (!shouldTimerRun && (_displayTimer?.isActive ?? false)) {
             _displayTimer?.cancel();
             final providerTime = gameProvider.elapsedTime;
             if (_displayTime.inSeconds != providerTime.inSeconds) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _displayTime = providerTime);
                 });
             }
         }

        String timeText = _formatDuration(_displayTime);
        final currentTheme = Theme.of(context);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeText,
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600, // Keep specific or make constant
                // --- UPDATED: Use constants for spacing/opacity ---
                letterSpacing: 0.5, // Keep specific or make constant
                 color: currentTheme.colorScheme.onSurface.withOpacity(0.95), // Keep specific or make constant
              ),
            ),
          ],
        );
      },
    );
  }
}