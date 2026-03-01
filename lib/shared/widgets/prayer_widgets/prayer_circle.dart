import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import 'countdown_timer.dart';

class PrayerCircle extends StatelessWidget {
  final String prayerName;
  final String formattedTime;
  final Duration timeUntil;
  final VoidCallback onTimerFinished;

  const PrayerCircle({
    super.key,
    required this.prayerName,
    required this.formattedTime,
    required this.timeUntil,
    required this.onTimerFinished,
  });

  @override
  Widget build(BuildContext context) {
    final minutesRemaining = timeUntil.inMinutes;

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prayerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            minutesRemaining > 0
                ? Text(
                    'Dans $minutesRemaining min',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  )
                : CountdownTimer(
                    duration: timeUntil,
                    onFinished: onTimerFinished,
                  ),
          ],
        ),
      ),
    );
  }
}
