// Optional Refactor: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:huedoku/widgets/settings_content.dart'; // Import the content widget

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      // Use the reusable settings content widget
      body: const SettingsContent(),
    );
  }
}