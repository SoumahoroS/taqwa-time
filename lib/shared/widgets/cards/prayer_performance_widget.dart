import 'package:flutter/material.dart';
import '../../../core/models/prayer_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../../core/services/encouragement_service.dart';
import '../glass/glass_card.dart';

class PrayerPerformanceWidget extends StatelessWidget {
  final Map<PrayerType, PrayerStatus> prayerStatuses;
  final int streak;
  final double weeklyCompletion;
  final String trend;

  const PrayerPerformanceWidget({
    super.key,
    required this.prayerStatuses,
    required this.streak,
    required this.weeklyCompletion,
    this.trend = 'stable',
  });

  @override
  Widget build(BuildContext context) {
    final encouragementService = EncouragementService();

    int totalPrayers = prayerStatuses.length;
    int completedPrayers = prayerStatuses.values
        .where((status) => status == PrayerStatus.onTime || status == PrayerStatus.late)
        .length;

    double todayPercentage = totalPrayers > 0
        ? (completedPrayers / totalPrayers) * 100
        : 0;

    String encouragementMessage = encouragementService.getEncouragementMessage(
      todayPrayers: prayerStatuses,
      streak: streak,
      weeklyCompletion: weeklyCompletion,
      trend: trend,
    );

    final showQuote = DateTime.now().second % 3 == 0;
    final islamicQuote = showQuote ? encouragementService.getIslamicQuote() : null;

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Votre performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$streak jours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMD),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressCircle(value: todayPercentage, label: "Aujourd'hui", color: AppColors.primaryLight),
              _buildProgressCircle(value: weeklyCompletion, label: "Cette semaine", color: AppColors.accent),
            ],
          ),

          const SizedBox(height: AppTokens.spacingMD),

          Container(
            padding: const EdgeInsets.all(AppTokens.spacingSM),
            decoration: BoxDecoration(
              color: _getEncouragementColor(todayPercentage).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
              border: Border.all(
                color: _getEncouragementColor(todayPercentage).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getEncouragementIcon(todayPercentage),
                  color: _getEncouragementColor(todayPercentage),
                  size: 24,
                ),
                const SizedBox(width: AppTokens.spacingSM),
                Expanded(
                  child: Text(
                    encouragementMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getEncouragementColor(todayPercentage),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (islamicQuote != null)
            Container(
              margin: const EdgeInsets.only(top: AppTokens.spacingSM),
              padding: const EdgeInsets.all(AppTokens.spacingSM),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rappel",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    islamicQuote,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppTokens.spacingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                trend == 'up' ? Icons.trending_up : trend == 'down' ? Icons.trending_down : Icons.trending_flat,
                size: 16,
                color: trend == 'up' ? AppColors.success : trend == 'down' ? AppColors.accent : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                trend == 'up' ? 'En progression' : trend == 'down' ? 'En régression' : 'Stable',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle({required double value, required String label, required Color color}) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Center(
                child: Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  IconData _getEncouragementIcon(double percentage) {
    if (percentage == 100) return Icons.star;
    if (percentage >= 80) return Icons.thumb_up;
    if (percentage >= 50) return Icons.trending_up;
    if (percentage >= 20) return Icons.notifications_active;
    return Icons.support;
  }

  Color _getEncouragementColor(double percentage) {
    if (percentage == 100) return AppColors.success;
    if (percentage >= 80) return AppColors.primaryLight;
    if (percentage >= 50) return AppColors.accent;
    if (percentage >= 20) return AppColors.accentLight;
    return AppColors.alertLight;
  }
}
