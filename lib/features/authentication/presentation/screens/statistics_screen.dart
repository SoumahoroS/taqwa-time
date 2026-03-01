import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/repositories/prayer_repository.dart';

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
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

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
      final weeklyStats = await _prayerRepository.getUserPrayerStats(userId, 7);
      final monthlyStats = await _prayerRepository.getUserPrayerStats(userId, 30);
      final dailyHistory = await _prayerRepository.getDailyPrayerHistory(userId, 30);
      setState(() {
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
        _dailyHistory = dailyHistory;
        _isLoading = false;
      });
      if (mounted) _animationController.forward();
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
        title: const Text('Statistiques', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTokens.spacingSM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
            ),
            child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadStatistics),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppTokens.spacingLG, AppTokens.spacingMD, AppTokens.spacingLG, AppTokens.spacingLG),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                                  ),
                                  child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: AppTokens.spacingMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Votre Performance', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                                      const SizedBox(height: 4),
                                      const Text('Statistiques Détaillées', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Period selector
                          GlassCard(
                            margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLG),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _buildPeriodTab('Semaine', 0),
                                _buildPeriodTab('Mois', 1),
                                _buildPeriodTab('Année', 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingLG),

                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMD),
                              child: Column(
                                children: [
                                  _buildStatsOverview(),
                                  const SizedBox(height: AppTokens.spacingMD),
                                  _buildWeeklyChart(),
                                  const SizedBox(height: AppTokens.spacingMD),
                                  _buildPrayerBreakdown(),
                                  const SizedBox(height: AppTokens.spacingMD),
                                  _buildAchievements(),
                                  const SizedBox(height: AppTokens.spacingLG),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String title, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
    final streak = stats['currentStreak'] ?? 0;
    final completionRate = total > 0 ? ((onTime + late) / total * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Taux de Réussite', '$completionRate%', Icons.check_circle_outline, AppColors.primaryLight)),
        const SizedBox(width: AppTokens.spacingMD),
        Expanded(child: _buildStatCard('Série Actuelle', '$streak jours', Icons.local_fire_department, AppColors.accentLight)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_dailyHistory == null || _dailyHistory!.isEmpty) return _buildEmptyChart();

    final dataToShow = _selectedPeriod == 0
        ? _dailyHistory!.skip(_dailyHistory!.length - 7).toList()
        : _dailyHistory!.toList();

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedPeriod == 0 ? 'Évolution Hebdomadaire' : 'Évolution Mensuelle',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('${dataToShow.length} jours', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryLight)),
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
                      children: dataToShow.map((day) => Container(margin: const EdgeInsets.symmetric(horizontal: 1), child: _buildChartBar(day, compact: true))).toList(),
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
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.analytics_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucune donnée disponible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Text('Commencez à enregistrer vos prières pour voir les statistiques', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('100%', AppColors.primaryLight),
        _buildLegendItem('75%', AppColors.primaryLight.withValues(alpha: 0.8)),
        _buildLegendItem('50%', AppColors.primaryLight.withValues(alpha: 0.6)),
        _buildLegendItem('25%', AppColors.primaryLight.withValues(alpha: 0.4)),
        _buildLegendItem('0%', Colors.white.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildChartBar(Map<String, dynamic> dayData, {bool compact = false}) {
    final total = dayData['total'] ?? 5;
    final onTime = dayData['onTime'] ?? 0;
    final late = dayData['late'] ?? 0;
    final completed = onTime + late;
    final hasData = dayData['hasData'] ?? false;
    final validCompleted = completed > total ? total : completed;
    final percentage = total > 0 ? validCompleted / total : 0.0;
    final day = dayData['day'] ?? '';

    Color barColor;
    if (!hasData) {
      barColor = Colors.white.withValues(alpha: 0.15);
    } else if (percentage >= 0.8) {
      barColor = AppColors.primaryLight;
    } else if (percentage >= 0.6) {
      barColor = AppColors.primaryLight.withValues(alpha: 0.8);
    } else if (percentage >= 0.4) {
      barColor = AppColors.primaryLight.withValues(alpha: 0.6);
    } else if (percentage >= 0.2) {
      barColor = AppColors.primaryLight.withValues(alpha: 0.4);
    } else {
      barColor = AppColors.alertLight.withValues(alpha: 0.6);
    }

    final barWidth = compact ? 8.0 : 24.0;
    final maxHeight = compact ? 60.0 : 80.0;

    return GestureDetector(
      onTap: () => _showDayDetails(dayData),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(hasData ? '${(percentage * 100).toInt()}%' : 'N/A', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          if (!compact) const SizedBox(height: 4),
          Container(
            width: barWidth,
            height: hasData ? (percentage * maxHeight).clamp(4.0, maxHeight) : 4.0,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(compact ? 4 : 12),
              boxShadow: hasData ? [BoxShadow(color: barColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            compact ? day.substring(0, 1) : (day.length >= 3 ? day.substring(0, 3) : day.substring(0, 1)),
            style: TextStyle(fontSize: compact ? 8 : 10, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
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
        backgroundColor: const Color(0xFF1A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMD)),
        title: Text('Détails du ${dayData['day']}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total prières', '${dayData['total']}'),
            _buildDetailRow('À l\'heure', '${dayData['onTime']}', AppColors.primaryLight),
            _buildDetailRow('En retard', '${dayData['late']}', AppColors.accentLight),
            _buildDetailRow('Manquées', '${dayData['missed']}', AppColors.alertLight),
            _buildDetailRow('Taux de réussite', '${dayData['successRate']}%', Colors.white),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer', style: TextStyle(color: AppColors.primaryLight))),
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
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

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition des Prières', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _buildBreakdownItem('À l\'heure', onTime, total, AppColors.primaryLight),
          const SizedBox(height: 12),
          _buildBreakdownItem('En retard', late, total, AppColors.accentLight),
          const SizedBox(height: 12),
          _buildBreakdownItem('Manquées', missed, total, AppColors.alertLight),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white))),
        Text('$count ($percentage%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildAchievements() {
    final stats = _weeklyStats;
    if (stats == null) return const SizedBox.shrink();
    final streak = stats['currentStreak'] ?? 0;
    final bestStreak = stats['bestStreak'] ?? 0;

    final achievements = [
      if (streak >= 7) {'icon': Icons.star, 'title': 'Semaine Parfaite', 'description': '$streak jours consécutifs', 'color': AppColors.accentLight},
      if (bestStreak >= 30) {'icon': Icons.emoji_events, 'title': 'Maître de la Discipline', 'description': 'Meilleure série: $bestStreak jours', 'color': AppColors.primaryLight},
    ];

    if (achievements.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accomplissements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ...achievements.map((achievement) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppTokens.spacingMD),
            decoration: BoxDecoration(
              color: (achievement['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
              border: Border.all(color: (achievement['color'] as Color).withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(achievement['icon'] as IconData, color: achievement['color'] as Color, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(achievement['title'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: achievement['color'] as Color)),
                      const SizedBox(height: 2),
                      Text(achievement['description'] as String, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
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
