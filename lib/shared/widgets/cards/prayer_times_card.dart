import 'package:flutter/material.dart';
import '../../../shared/themes/app_tokens.dart';
import '../prayer_widgets/prayer_time_item.dart';
import '../../../core/models/prayer_model.dart';
import '../../../core/services/prayer_time_service.dart';
import '../glass/glass_card.dart';

class PrayerTimesCard extends StatelessWidget {
  final Map<PrayerType, DateTime> prayerTimes;
  final PrayerType? nextPrayerType;
  final PrayerTimeService prayerTimeService;

  const PrayerTimesCard({
    super.key,
    required this.prayerTimes,
    required this.nextPrayerType,
    required this.prayerTimeService,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horaires du jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppTokens.spacingMD),
          _buildPrayerTimeItem('Fajr', prayerTimes[PrayerType.fajr]!),
          _buildPrayerTimeItem('Dhuhr', prayerTimes[PrayerType.dhuhr]!),
          _buildPrayerTimeItem('Asr', prayerTimes[PrayerType.asr]!),
          _buildPrayerTimeItem('Maghrib', prayerTimes[PrayerType.maghrib]!),
          _buildPrayerTimeItem('Isha', prayerTimes[PrayerType.isha]!),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeItem(String name, DateTime time) {
    final formattedTime = prayerTimeService.formatPrayerTime(time);
    final isNext = nextPrayerType != null &&
        prayerTimeService.getPrayerName(nextPrayerType!) == name;

    return PrayerTimeItem(
      name: name,
      formattedTime: formattedTime,
      isNext: isNext,
    );
  }
}
