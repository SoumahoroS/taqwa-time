// lib/shared/widgets/cards/prayer_performance_widget.dart

import 'package:flutter/material.dart';
import '../../../core/models/prayer_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../core/services/encouragement_service.dart';

class PrayerPerformanceWidget extends StatelessWidget {
  final Map<PrayerType, PrayerStatus> prayerStatuses;
  final int streak; // Nombre de jours consécutifs avec toutes les prières accomplies
  final double weeklyCompletion; // Pourcentage de complétion cette semaine
  final String trend; // Tendance: 'up', 'down', 'stable'

  const PrayerPerformanceWidget({
    Key? key,
    required this.prayerStatuses,
    required this.streak,
    required this.weeklyCompletion,
    this.trend = 'stable',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser le service d'encouragement
    final encouragementService = EncouragementService();

    // Calcul des statistiques pour aujourd'hui
    int totalPrayers = prayerStatuses.length;
    int completedPrayers = prayerStatuses.values
        .where((status) => status == PrayerStatus.onTime || status == PrayerStatus.late)
        .length;
    int onTimePrayers = prayerStatuses.values
        .where((status) => status == PrayerStatus.onTime)
        .length;
    int missedPrayers = prayerStatuses.values
        .where((status) => status == PrayerStatus.missed)
        .length;

    double todayPercentage = totalPrayers > 0
        ? (completedPrayers / totalPrayers) * 100
        : 0;

    // Obtenir un message d'encouragement adapté
    String encouragementMessage = encouragementService.getEncouragementMessage(
      todayPrayers: prayerStatuses,
      streak: streak,
      weeklyCompletion: weeklyCompletion,
      trend: trend,
    );

    // Obtenir une citation islamique (affichée occasionnellement)
    final showQuote = DateTime.now().second % 3 == 0; // ~33% de chance
    final islamicQuote = showQuote ? encouragementService.getIslamicQuote() : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Votre performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                // Badge indiquant le streak actuel
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ),
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
            const SizedBox(height: 16),

            // Statistiques sous forme de segments de cercle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressCircle(
                  value: todayPercentage,
                  label: "Aujourd'hui",
                  color: AppColors.primary,
                ),
                _buildProgressCircle(
                  value: weeklyCompletion,
                  label: "Cette semaine",
                  color: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Messages d'encouragement basés sur la performance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEncouragementIcon(todayPercentage),
                    color: _getEncouragementColor(todayPercentage),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
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

            // Citation islamique (affichée occasionnellement)
            if (islamicQuote != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rappel",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      islamicQuote,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            // Petit indicateur de tendance
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  trend == 'up'
                      ? Icons.trending_up
                      : trend == 'down'
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  size: 16,
                  color: trend == 'up'
                      ? Colors.green
                      : trend == 'down'
                      ? Colors.orange
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  trend == 'up'
                      ? 'En progression'
                      : trend == 'down'
                      ? 'En régression'
                      : 'Stable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle({
    required double value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            children: [
              // Cercle de fond
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                ),
              ),
              // Cercle de progression
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              // Texte au centre
              Center(
                child: Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  IconData _getEncouragementIcon(double percentage) {
    if (percentage == 100) {
      return Icons.star;
    } else if (percentage >= 80) {
      return Icons.thumb_up;
    } else if (percentage >= 50) {
      return Icons.trending_up;
    } else if (percentage >= 20) {
      return Icons.notifications_active;
    } else {
      return Icons.support;
    }
  }

  Color _getEncouragementColor(double percentage) {
    if (percentage == 100) {
      return Colors.green;
    } else if (percentage >= 80) {
      return AppColors.primary;
    } else if (percentage >= 50) {
      return AppColors.accent;
    } else if (percentage >= 20) {
      return Colors.orange;
    } else {
      return AppColors.alert;
    }
  }
}