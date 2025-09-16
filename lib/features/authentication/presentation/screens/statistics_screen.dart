// lib/features/statistics/presentation/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/models/prayer_model.dart';
import 'dart:math' as math;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AuthService _authService;
  late PrayerRepository _prayerRepository;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _monthlyStats;
  List<Map<String, dynamic>>? _dailyHistory;
  bool _isLoading = true;
  int _selectedPeriod = 0; // 0: Semaine, 1: Mois, 2: Année

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    if (_authService.currentUser == null) return;

    final userId = _authService.currentUser!.uid;

    setState(() => _isLoading = true);

    try {
      // Charger les statistiques
      final weeklyStats = await _prayerRepository.getUserPrayerStats(userId, 7);
      final monthlyStats = await _prayerRepository.getUserPrayerStats(userId, 30);
      final dailyHistory = await _prayerRepository.getDailyPrayerHistory(userId, 30);

      setState(() {
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
        _dailyHistory = dailyHistory;
        _isLoading = false;
      });

      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Statistiques',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadStatistics,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              AppColors.background,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // En-tête moderne
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.analytics_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Votre Performance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Statistiques Détaillées',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sélecteur de période
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildPeriodTab('Semaine', 0),
                              _buildPeriodTab('Mois', 1),
                              _buildPeriodTab('Année', 2),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contenu principal
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                              child: Column(
                                children: [
                                  _buildStatsOverview(),
                                  const SizedBox(height: 24),
                                  _buildWeeklyChart(),
                                  const SizedBox(height: 24),
                                  _buildPrayerBreakdown(),
                                  const SizedBox(height: 24),
                                  _buildAchievements(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String title, int index) {
    final isSelected = _selectedPeriod == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final stats = _selectedPeriod == 0 ? _weeklyStats : _monthlyStats;
    if (stats == null) return const SizedBox.shrink();

    final total = stats['total'] ?? 0;
    final onTime = stats['onTime'] ?? 0;
    final late = stats['late'] ?? 0;
    final missed = stats['missed'] ?? 0;
    final streak = stats['currentStreak'] ?? 0;
    
    final completionRate = total > 0 ? ((onTime + late) / total * 100).toInt() : 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Taux de Réussite',
            '$completionRate%',
            Icons.check_circle_outline,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Série Actuelle',
            '$streak jours',
            Icons.local_fire_department,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_dailyHistory == null || _dailyHistory!.isEmpty) {
      return _buildEmptyChart();
    }

    // Prendre les données selon la période sélectionnée
    final dataToShow = _selectedPeriod == 0 
        ? _dailyHistory!.skip(_dailyHistory!.length - 7).toList()  // Semaine: 7 derniers jours
        : _dailyHistory!.toList(); // Mois: 30 derniers jours

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedPeriod == 0 ? 'Évolution Hebdomadaire' : 'Évolution Mensuelle',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dataToShow.length} jours',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: _selectedPeriod == 0 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: dataToShow.map((day) => _buildChartBar(day)).toList(),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dataToShow.map((day) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        child: _buildChartBar(day, compact: true),
                      )).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à enregistrer vos prières pour voir les statistiques',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('100%', AppColors.primary),
        _buildLegendItem('75%', AppColors.primary.withOpacity(0.8)),
        _buildLegendItem('50%', AppColors.primary.withOpacity(0.6)),
        _buildLegendItem('25%', AppColors.primary.withOpacity(0.4)),
        _buildLegendItem('0%', Colors.grey[300]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar(Map<String, dynamic> dayData, {bool compact = false}) {
    final total = dayData['total'] ?? 5;
    final onTime = dayData['onTime'] ?? 0;
    final late = dayData['late'] ?? 0;
    final completed = onTime + late;
    final hasData = dayData['hasData'] ?? false;
    
    // Validation: s'assurer que completed ne dépasse pas total
    final validCompleted = completed > total ? total : completed;
    final percentage = total > 0 ? validCompleted / total : 0.0;
    final day = dayData['day'] ?? '';
    
    // Déterminer la couleur selon le pourcentage et la présence de données
    Color barColor;
    if (!hasData) {
      barColor = Colors.grey[300]!;
    } else if (percentage >= 0.8) {
      barColor = AppColors.primary;
    } else if (percentage >= 0.6) {
      barColor = AppColors.primary.withOpacity(0.8);
    } else if (percentage >= 0.4) {
      barColor = AppColors.primary.withOpacity(0.6);
    } else if (percentage >= 0.2) {
      barColor = AppColors.primary.withOpacity(0.4);
    } else {
      barColor = AppColors.alert.withOpacity(0.6);
    }
    
    final barWidth = compact ? 8.0 : 24.0;
    final maxHeight = compact ? 60.0 : 80.0;
    
    return GestureDetector(
      onTap: () => _showDayDetails(dayData),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tooltip avec pourcentage
          if (!compact) Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hasData ? '${(percentage * 100).toInt()}%' : 'N/A',
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!compact) const SizedBox(height: 4),
          
          // Barre du graphique
          Container(
            width: barWidth,
            height: hasData ? (percentage * maxHeight).clamp(4.0, maxHeight) : 4.0,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(compact ? 4 : 12),
              boxShadow: hasData ? [
                BoxShadow(
                  color: barColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Label du jour
          Text(
            compact 
                ? day.substring(0, 1)
                : (day.length >= 3 ? day.substring(0, 3) : day.substring(0, 1)),
            style: TextStyle(
              fontSize: compact ? 8 : 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(Map<String, dynamic> dayData) {
    final hasData = dayData['hasData'] ?? false;
    if (!hasData) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du ${dayData['day']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total prières', '${dayData['total']}'),
            _buildDetailRow('À l\'heure', '${dayData['onTime']}', AppColors.primary),
            _buildDetailRow('En retard', '${dayData['late']}', AppColors.accent),
            _buildDetailRow('Manquées', '${dayData['missed']}', AppColors.alert),
            _buildDetailRow('Taux de réussite', '${dayData['successRate']}%', AppColors.secondary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerBreakdown() {
    final stats = _selectedPeriod == 0 ? _weeklyStats : _monthlyStats;
    if (stats == null) return const SizedBox.shrink();

    final total = stats['total'] ?? 0;
    if (total == 0) return const SizedBox.shrink();

    final onTime = stats['onTime'] ?? 0;
    final late = stats['late'] ?? 0;
    final missed = stats['missed'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition des Prières',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem('À l\'heure', onTime, total, AppColors.primary),
          const SizedBox(height: 12),
          _buildBreakdownItem('En retard', late, total, AppColors.accent),
          const SizedBox(height: 12),
          _buildBreakdownItem('Manquées', missed, total, AppColors.alert),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count ($percentage%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final stats = _weeklyStats;
    if (stats == null) return const SizedBox.shrink();

    final streak = stats['currentStreak'] ?? 0;
    final bestStreak = stats['bestStreak'] ?? 0;
    
    final achievements = [
      if (streak >= 7) {
        'icon': Icons.star,
        'title': 'Semaine Parfaite',
        'description': '$streak jours consécutifs',
        'color': AppColors.accent,
      },
      if (bestStreak >= 30) {
        'icon': Icons.emoji_events,
        'title': 'Maître de la Discipline',
        'description': 'Meilleure série: $bestStreak jours',
        'color': AppColors.primary,
      },
    ];

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accomplissements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          ...achievements.map((achievement) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (achievement['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (achievement['color'] as Color).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  achievement['icon'] as IconData,
                  color: achievement['color'] as Color,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: achievement['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}