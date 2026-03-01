import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';

class PrayerIndicator extends StatelessWidget {
  final String name;
  final bool isPrayed;

  const PrayerIndicator({
    super.key,
    required this.name,
    required this.isPrayed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrayed ? Colors.white : Colors.transparent,
            border: Border.all(
              color: isPrayed ? Colors.white : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: isPrayed
              ? const Icon(Icons.check, size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
