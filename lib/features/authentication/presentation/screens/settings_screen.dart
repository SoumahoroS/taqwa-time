// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../../shared/themes/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Écran des paramètres en cours de développement'),
      ),
    );
  }
}