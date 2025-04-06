import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';

class PrayerIndicator extends StatelessWidget {
  final String name;
  final bool isPrayed;

  const PrayerIndicator({
    Key? key,
    required this.name,
    required this.isPrayed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrayed ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isPrayed ? AppColors.primary : Colors.grey[600]!,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}