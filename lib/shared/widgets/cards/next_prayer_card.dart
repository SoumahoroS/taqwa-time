import 'package:flutter/material.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/themes/app_colors.dart';
import '../prayer_widgets/prayer_circle.dart';
import '../prayer_widgets/prayer_indicator.dart';
import '../../../core/models/prayer_model.dart';
import '../../../routes.dart';

class NextPrayerCard extends StatelessWidget {
  final String prayerName;
  final String formattedTime;
  final Duration timeUntil;
  final VoidCallback onTimerFinished;
  final Map<PrayerType, DateTime> prayerTimes;
  final Map<PrayerType, bool> prayedStatus;
  final PrayerTimeService prayerTimeService;
  final Map<PrayerType, PrayerStatus> prayerStatuses;

  const NextPrayerCard({
    Key? key,
    required this.prayerName,
    required this.formattedTime,
    required this.timeUntil,
    required this.onTimerFinished,
    required this.prayerTimes,
    required this.prayedStatus,
    required this.prayerTimeService,
    required this.prayerStatuses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Prochaine Prière',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Horloge de prière
          PrayerCircle(
            prayerName: prayerName,
            formattedTime: formattedTime,
            timeUntil: timeUntil,
            onTimerFinished: onTimerFinished,
          ),

          const SizedBox(height: 20),

          // Indicateurs de prière
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prières d\'aujourd\'hui',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PrayerIndicator(name: 'Fajr', isPrayed: prayedStatus[PrayerType.fajr] ?? false),
                    PrayerIndicator(name: 'Dhuhr', isPrayed: prayedStatus[PrayerType.dhuhr] ?? false),
                    PrayerIndicator(name: 'Asr', isPrayed: prayedStatus[PrayerType.asr] ?? false),
                    PrayerIndicator(name: 'Maghrib', isPrayed: prayedStatus[PrayerType.maghrib] ?? false),
                    PrayerIndicator(name: 'Isha', isPrayed: prayedStatus[PrayerType.isha] ?? false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bouton pour aller à l'écran de suivi des prières
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.prayerTracking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Voir toutes les prières',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}