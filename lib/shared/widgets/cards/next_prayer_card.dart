import 'package:flutter/material.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/themes/app_tokens.dart';
import '../prayer_widgets/prayer_circle.dart';
import '../prayer_widgets/prayer_indicator.dart';
import '../../../core/models/prayer_model.dart';
import '../../../routes.dart';
import '../glass/glass_card.dart';
import '../glass/glass_button.dart';

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
    super.key,
    required this.prayerName,
    required this.formattedTime,
    required this.timeUntil,
    required this.onTimerFinished,
    required this.prayerTimes,
    required this.prayedStatus,
    required this.prayerTimeService,
    required this.prayerStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        children: [
          Text(
            'Prochaine Prière',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTokens.spacingMD),

          PrayerCircle(
            prayerName: prayerName,
            formattedTime: formattedTime,
            timeUntil: timeUntil,
            onTimerFinished: onTimerFinished,
          ),

          const SizedBox(height: AppTokens.spacingLG),

          GlassCard(
            borderRadius: AppTokens.radiusSM,
            padding: const EdgeInsets.all(AppTokens.spacingSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prières d\'aujourd\'hui',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSM),
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

          const SizedBox(height: AppTokens.spacingLG),

          GlassButton(
            label: 'Voir toutes les prières',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.prayerTracking),
            variant: GlassButtonVariant.primary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
