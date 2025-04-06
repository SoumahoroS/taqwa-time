// lib/features/statistics/presentation/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import '../../../../shared/themes/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Écran des statistiques en cours de développement'),
      ),
    );
  }
}