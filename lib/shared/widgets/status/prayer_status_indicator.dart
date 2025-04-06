import 'package:flutter/material.dart';
import '../../../core/models/prayer_model.dart';
import '../../themes/app_colors.dart';

class PrayerStatusIndicator extends StatelessWidget {
  final PrayerStatus status;

  const PrayerStatusIndicator({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case PrayerStatus.onTime:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'À l\'heure';
        break;
      case PrayerStatus.late:
        color = AppColors.accent;
        icon = Icons.check_circle_outline;
        label = 'En retard';
        break;
      case PrayerStatus.missed:
        color = AppColors.alert;
        icon = Icons.cancel;
        label = 'Manquée';
        break;
      case PrayerStatus.notYet:
        color = Colors.grey;
        icon = Icons.schedule;
        label = 'À venir';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}