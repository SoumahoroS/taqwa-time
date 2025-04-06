// lib/features/quran/presentation/screens/quran_screen.dart
import 'package:flutter/material.dart';
import '../../../../shared/themes/app_colors.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coran'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Écran du Coran en cours de développement'),
      ),
    );
  }
}