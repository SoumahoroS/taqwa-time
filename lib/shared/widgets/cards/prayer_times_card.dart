import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../prayer_widgets/prayer_time_item.dart';
import '../../../core/models/prayer_model.dart';
import '../../../core/services/prayer_time_service.dart';

class PrayerTimesCard extends StatelessWidget {
  final Map<PrayerType, DateTime> prayerTimes;
  final PrayerType? nextPrayerType;
  final PrayerTimeService prayerTimeService;

  const PrayerTimesCard({
    Key? key,
    required this.prayerTimes,
    required this.nextPrayerType,
    required this.prayerTimeService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horaires du jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
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