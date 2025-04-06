import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import 'countdown_timer.dart';

class PrayerCircle extends StatelessWidget {
  final String prayerName;
  final String formattedTime;
  final Duration timeUntil;
  final VoidCallback onTimerFinished;

  const PrayerCircle({
    Key? key,
    required this.prayerName,
    required this.formattedTime,
    required this.timeUntil,
    required this.onTimerFinished,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final minutesRemaining = timeUntil.inMinutes;

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
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
                color: AppColors.primary,
              ),
            ),
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            minutesRemaining > 0
                ? Text(
              'Dans $minutesRemaining min',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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