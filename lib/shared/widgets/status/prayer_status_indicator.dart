import 'package:flutter/material.dart';
import '../../../core/models/prayer_model.dart';
import '../../themes/app_colors.dart';

class PrayerStatusIndicator extends StatelessWidget {
  final PrayerStatus status;

  const PrayerStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case PrayerStatus.onTime:
        color = AppColors.success;
        icon = Icons.check_circle;
        label = 'À l\'heure';
      case PrayerStatus.late:
        color = AppColors.accent;
        icon = Icons.check_circle_outline;
        label = 'En retard';
      case PrayerStatus.missed:
        color = AppColors.alert;
        icon = Icons.cancel;
        label = 'Manquée';
      case PrayerStatus.notYet:
        color = Colors.white.withValues(alpha: 0.5);
        icon = Icons.schedule;
        label = 'À venir';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
