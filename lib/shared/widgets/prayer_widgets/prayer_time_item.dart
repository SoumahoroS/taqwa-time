import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/themes/app_tokens.dart';

class PrayerTimeItem extends StatelessWidget {
  final String name;
  final String formattedTime;
  final bool isNext;

  const PrayerTimeItem({
    super.key,
    required this.name,
    required this.formattedTime,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: isNext ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: isNext ? BorderRadius.circular(AppTokens.radiusSM) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.access_time,
                color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMD),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: Colors.white.withValues(alpha: isNext ? 1.0 : 0.85),
              ),
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? AppColors.accent : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
