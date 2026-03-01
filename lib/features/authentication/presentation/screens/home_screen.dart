import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/models/prayer_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_bottom_nav.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';
import '../../../../shared/widgets/navigation/taqwa_time_drawer.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late PrayerTimeService _prayerTimeService;
  late AuthService _authService;
  late PrayerRepository _prayerRepository;

  Map<PrayerType, DateTime>? _prayerTimes;
  Map<PrayerType, PrayerStatus> _prayerStatuses = {};
  PrayerType? _nextPrayerType;
  DateTime? _nextPrayerTime;
  Timer? _refreshTimer;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  UserModel? _currentUser;
  int _streak = 0;
  double _weeklyCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    _initialize();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _updateNextPrayer();
        _loadTodayPrayers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _loadCurrentUser();
      await _loadPrayerTimes();
      await _loadTodayPrayers();
      await _loadPrayerStats();
      await _updateNextPrayer();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        setState(() => _currentUser = userData);
      }
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayerTimes = await _prayerTimeService.getAllPrayerTimes();
    setState(() => _prayerTimes = prayerTimes);
  }

  Future<void> _loadTodayPrayers() async {
    if (_authService.currentUser == null) return;
    if (_authService.isGuestUser) return;

    final userId = _authService.currentUser!.uid;
    final today = DateTime.now();

    try {
      final prayers = await _prayerRepository.getUserPrayers(userId, today).first;

      if (prayers.isNotEmpty) {
        Map<PrayerType, PrayerStatus> statuses = {};
        for (var prayer in prayers) {
          statuses[prayer.type] = prayer.status;
        }
        setState(() => _prayerStatuses = statuses);
      } else {
        final newPrayers = await _prayerTimeService.createDailyPrayers(
          userId: userId,
          date: today,
        );
        Map<PrayerType, PrayerStatus> statuses = {};
        for (var prayer in newPrayers) {
          statuses[prayer.type] = prayer.status;
        }
        await _prayerRepository.savePrayers(newPrayers);
        setState(() => _prayerStatuses = statuses);
      }
    } catch (e) {
      print('Erreur lors du chargement des prières: $e');
    }
  }

  Future<void> _loadPrayerStats() async {
    if (_authService.currentUser == null) return;
    if (_authService.isGuestUser) return;

    final userId = _authService.currentUser!.uid;
    try {
      final stats = await _prayerRepository.getUserPrayerStats(userId, 7);
      setState(() {
        _streak = stats['currentStreak'] ?? 0;
        int total = stats['total'] ?? 0;
        int completed = (stats['onTime'] ?? 0) + (stats['late'] ?? 0);
        _weeklyCompletion = total > 0 ? (completed / total) * 100 : 0;
      });
      if (_streak > 0) {
        await _prayerRepository.updateBestStreak(userId, _streak);
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> _updateNextPrayer() async {
    try {
      final (nextType, nextTime) = await _prayerTimeService.getNextPrayer();
      setState(() {
        _nextPrayerType = nextType;
        _nextPrayerTime = nextTime;
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la prochaine prière: $e');
    }
  }

  void _navigateToStatistics() {
    if (_authService.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, '/statistics');
    }
  }

  void _navigateToPrayerTracking() {
    if (_authService.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, '/prayer-tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('TaqwaTime'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [_buildRefreshButton()],
      ),
      drawer: TaqwaTimeDrawer(currentUser: _currentUser),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              _navigateToPrayerTracking();
              break;
            case 2:
              Navigator.pushNamed(context, '/quran');
              break;
            case 3:
              _navigateToStatistics();
              break;
          }
        },
        items: const [
          GlassBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
          GlassBottomNavItem(icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled, label: 'Prières'),
          GlassBottomNavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Coran'),
          GlassBottomNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppTokens.spacingSM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: _initialize,
        tooltip: 'Actualiser',
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        const GradientMeshBackground(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                borderRadius: 100,
                padding: const EdgeInsets.all(AppTokens.spacingLG),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: AppTokens.spacingLG),
              Text(
                'Chargement...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        const GradientMeshBackground(),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacingMD,
              AppTokens.spacingSM,
              AppTokens.spacingMD,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppTokens.spacingLG),
                _buildNextPrayerSection(),
                const SizedBox(height: AppTokens.spacingLG),
                _buildPerformanceSection(),
                const SizedBox(height: AppTokens.spacingLG),
                _buildIslamicReminder(),
                const SizedBox(height: AppTokens.spacingLG),
                _buildPrayerTimesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSM),
      child: Row(
        children: [
          // Avatar
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Icon(
              _authService.isGuestUser ? Icons.person_outline_rounded : Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTokens.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salam aleykoum',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _authService.isGuestUser
                      ? 'Invité'
                      : _currentUser?.name ?? 'Utilisateur',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!_authService.isGuestUser) _buildStreakBadge(),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GlassCard(
            borderRadius: 20,
            tintColor: AppColors.accent.withValues(alpha: 0.3),
            borderColor: AppColors.accentLight.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextPrayerSection() {
    if (_nextPrayerTime == null || _nextPrayerType == null || _prayerTimes == null) {
      return const SizedBox.shrink();
    }

    final prayerName = _prayerTimeService.getPrayerName(_nextPrayerType!);
    final formattedTime = _prayerTimeService.formatPrayerTime(_nextPrayerTime!);
    final timeUntil = _prayerTimeService.timeUntilNextPrayer(_nextPrayerTime!);
    final minutesRemaining = timeUntil.inMinutes;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: GlassCard(
              borderRadius: AppTokens.radiusXL,
              padding: const EdgeInsets.all(28),
              tintColor: AppColors.primary.withValues(alpha: 0.2),
              borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Column(
                children: [
                  Text(
                    'PROCHAINE PRIÈRE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLG),

                  // Prayer circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 3,
                      ),
                      color: Colors.white.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
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
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spacingLG),

                  // Time remaining pill
                  GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      minutesRemaining > 60
                          ? 'Dans ${(minutesRemaining / 60).floor()}h ${minutesRemaining % 60}min'
                          : 'Dans $minutesRemaining min',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildPrayerIndicators(),

                  const SizedBox(height: AppTokens.spacingLG),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToPrayerTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: const Text(
                        'VOIR LES DÉTAILS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerIndicators() {
    final prayers = [
      (PrayerType.fajr, 'Fajr'),
      (PrayerType.dhuhr, 'Dhuhr'),
      (PrayerType.asr, 'Asr'),
      (PrayerType.maghrib, 'Maghrib'),
      (PrayerType.isha, 'Isha'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: prayers.map((prayer) {
        final status = _prayerStatuses[prayer.$1] ?? PrayerStatus.notYet;
        final isCompleted = status == PrayerStatus.onTime || status == PrayerStatus.late;
        final isNext = prayer.$1 == _nextPrayerType;

        return Column(
          children: [
            Container(
              width: isNext ? 32 : 28,
              height: isNext ? 32 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: isNext
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: isCompleted ? 1.0 : 0.4),
                  width: isNext ? 3 : 2,
                ),
                boxShadow: isNext
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              prayer.$2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white.withValues(alpha: isNext ? 1.0 : 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceSection() {
    if (_prayerStatuses.isEmpty) return const SizedBox.shrink();

    final totalPrayers = _prayerStatuses.length;
    final completedPrayers = _prayerStatuses.values
        .where((s) => s == PrayerStatus.onTime || s == PrayerStatus.late)
        .length;
    final todayPercentage = totalPrayers > 0 ? (completedPrayers / totalPrayers) * 100 : 0.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: AppTokens.spacingSM),
                  child: Text(
                    'Votre Performance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingMD),

                GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildPerformanceCircle(
                              value: todayPercentage,
                              label: "Aujourd'hui",
                              color: AppColors.primaryLight,
                              animate: value,
                            ),
                          ),
                          Expanded(
                            child: _buildPerformanceCircle(
                              value: _weeklyCompletion,
                              label: 'Cette semaine',
                              color: AppColors.accent,
                              animate: value,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingLG),
                      _buildPerformanceMessage(todayPercentage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCircle({
    required double value,
    required String label,
    required Color color,
    required double animate,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: (value / 100) * animate,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(value * animate).toInt()}%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacingSM),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMessage(double percentage) {
    final dayIndex = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;

    IconData icon;
    String message;
    Color color;

    if (percentage == 100) {
      color = AppColors.success;
      final msgs = [
        (Icons.emoji_events_rounded, 'MashaAllah ! Toutes vos prières sont accomplies'),
        (Icons.star_rounded, 'SubhanAllah, une journée de dévotion parfaite !'),
        (Icons.mosque_rounded, 'Barakallahu fikoum ! Chaque salat accompli élève votre rang'),
        (Icons.favorite_rounded, 'MashaAllah, la régularité est la clé du Paradis'),
        (Icons.auto_awesome_rounded, 'SubhanAllah ! Les anges témoignent de votre fidélité'),
      ];
      final pick = msgs[dayIndex % msgs.length];
      icon = pick.$1; message = pick.$2;
    } else if (percentage >= 80) {
      color = AppColors.primaryLight;
      final msgs = [
        (Icons.trending_up_rounded, 'SubhanAllah, excellent travail ! Continuez ainsi'),
        (Icons.bolt_rounded, 'MashaAllah, vous êtes sur la bonne voie !'),
        (Icons.thumb_up_rounded, 'Allah récompense l\'effort sincère, persévérez !'),
        (Icons.local_fire_department_rounded, 'Votre constance est une marque de foi solide'),
        (Icons.verified_rounded, 'Presque parfait ! Une prière de plus et c\'est accompli'),
      ];
      final pick = msgs[dayIndex % msgs.length];
      icon = pick.$1; message = pick.$2;
    } else if (percentage >= 50) {
      color = AppColors.accent;
      final msgs = [
        (Icons.lightbulb_outline_rounded, 'Alhamdulillah, bon effort ! Vous progressez'),
        (Icons.auto_graph_rounded, 'Chaque prière accomplie est une lumière pour vous'),
        (Icons.psychology_rounded, 'Allah aime les actions régulières même si petites'),
        (Icons.volunteer_activism_rounded, 'Continuez, la foi grandit avec la pratique'),
        (Icons.directions_run_rounded, 'Insha\'Allah, demain vous serez encore meilleur'),
      ];
      final pick = msgs[dayIndex % msgs.length];
      icon = pick.$1; message = pick.$2;
    } else {
      color = AppColors.alertLight;
      final msgs = [
        (Icons.favorite_outline_rounded, 'Chaque prière compte, Insha\'Allah vous y arriverez !'),
        (Icons.restart_alt_rounded, 'Il n\'est jamais trop tard pour revenir à Allah'),
        (Icons.spa_rounded, 'Commencez par une prière à la fois, Allah est Al-Ghafour'),
        (Icons.wb_sunny_rounded, 'Chaque nouveau jour est une chance de recommencer'),
        (Icons.handshake_rounded, 'Allah tend Sa main à celui qui revient à Lui'),
      ];
      final pick = msgs[dayIndex % msgs.length];
      icon = pick.$1; message = pick.$2;
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTokens.spacingSM),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicReminder() {
    final dayIndex = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;

    final reminders = [
      {
        'type': 'Coran',
        'arabic': 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
        'translation': '« La prière a été prescrite aux croyants à des horaires fixes. »',
        'source': 'Sourate An-Nisa\' — 4:103',
      },
      {
        'type': 'Hadith',
        'arabic': 'الصَّلَاةُ عِمَادُ الدِّينِ',
        'translation': '« La prière est le pilier de la religion. »',
        'source': 'Rapporté par At-Tirmidhi',
      },
      {
        'type': 'Coran',
        'arabic': 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
        'translation': '« Cherchez de l\'aide dans la patience et la prière. »',
        'source': 'Sourate Al-Baqarah — 2:45',
      },
      {
        'type': 'Hadith',
        'arabic': 'أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ',
        'translation': '« Le serviteur est le plus proche de son Seigneur lorsqu\'il est en prosternation. »',
        'source': 'Sahih Muslim',
      },
      {
        'type': 'Coran',
        'arabic': 'إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ',
        'translation': '« La prière préserve de la turpitude et du blâmable. »',
        'source': 'Sourate Al-Ankabut — 29:45',
      },
      {
        'type': 'Hadith',
        'arabic': 'إِنَّ اللَّهَ يُحِبُّ مِنَ الْعَمَلِ مَا دَاوَمَ عَلَيْهِ صَاحِبُهُ وَإِنْ قَلَّ',
        'translation': '« Allah aime l\'action que son auteur accomplit régulièrement, même si elle est peu importante. »',
        'source': 'Sahih Al-Bukhari',
      },
      {
        'type': 'Coran',
        'arabic': 'أَقِمِ الصَّلَاةَ لِذِكْرِي',
        'translation': '« Accomplis la prière pour te souvenir de Moi. »',
        'source': 'Sourate Taha — 20:14',
      },
      {
        'type': 'Hadith',
        'arabic': 'الصَّلَوَاتُ الخَمْسُ كَفَّارَةٌ لِمَا بَيْنَهُنَّ',
        'translation': '« Les cinq prières sont une expiation pour les péchés commis entre elles. »',
        'source': 'Sahih Muslim',
      },
      {
        'type': 'Coran',
        'arabic': 'قَدْ أَفْلَحَ الْمُؤْمِنُونَ ۝ الَّذِينَ هُمْ فِي صَلَاتِهِمْ خَاشِعُونَ',
        'translation': '« Certes, ont réussi les croyants, ceux qui sont humbles dans leur prière. »',
        'source': 'Sourate Al-Mu\'minun — 23:1-2',
      },
      {
        'type': 'Hadith',
        'arabic': 'أَوَّلُ مَا يُحَاسَبُ بِهِ الْعَبْدُ يَوْمَ الْقِيَامَةِ الصَّلَاةُ',
        'translation': '« La première chose dont le serviteur sera jugé le Jour du Jugement est la prière. »',
        'source': 'Sunan Abu Dawud',
      },
      {
        'type': 'Coran',
        'arabic': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
        'translation': '« C\'est par le rappel d\'Allah que les cœurs trouvent leur quiétude. »',
        'source': 'Sourate Ar-Ra\'d — 13:28',
      },
      {
        'type': 'Hadith',
        'arabic': 'مَنْ حَافَظَ عَلَيْهَا كَانَتْ لَهُ نُورًا وَبُرْهَانًا وَنَجَاةً يَوْمَ الْقِيَامَةِ',
        'translation': '« Celui qui préserve la prière aura une lumière, une preuve et un salut le Jour du Jugement. »',
        'source': 'Musnad Ahmad',
      },
    ];

    final reminder = reminders[dayIndex % reminders.length];
    final isQuran = reminder['type'] == 'Coran';
    final color = isQuran ? AppColors.primaryLight : AppColors.accent;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1100),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppTokens.spacingSM),
                  child: Row(
                    children: [
                      Text(
                        isQuran ? 'Verset du Jour' : 'Hadith du Jour',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          reminder['type']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spacingMD),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  tintColor: color.withValues(alpha: 0.08),
                  borderColor: color.withValues(alpha: 0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Arabic text
                      Text(
                        reminder['arabic']!,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.8,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              color.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Translation
                      Text(
                        reminder['translation']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Source
                      Row(
                        children: [
                          Icon(
                            isQuran ? Icons.menu_book_rounded : Icons.bookmark_rounded,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reminder['source']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimesSection() {
    if (_prayerTimes == null) return const SizedBox.shrink();

    final prayers = [
      (PrayerType.fajr, 'Fajr', Icons.wb_twilight_rounded),
      (PrayerType.dhuhr, 'Dhuhr', Icons.wb_sunny_rounded),
      (PrayerType.asr, 'Asr', Icons.wb_cloudy_rounded),
      (PrayerType.maghrib, 'Maghrib', Icons.wb_twilight_rounded),
      (PrayerType.isha, 'Isha', Icons.nights_stay_rounded),
    ];

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: AppTokens.spacingSM),
                  child: Text(
                    'Horaires du Jour',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingMD),

                GlassCard(
                  padding: const EdgeInsets.all(AppTokens.spacingSM),
                  child: Column(
                    children: prayers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final prayer = entry.value;
                      final time = _prayerTimes![prayer.$1]!;
                      final formattedTime = _prayerTimeService.formatPrayerTime(time);
                      final isNext = prayer.$1 == _nextPrayerType;

                      return _buildPrayerTimeItem(
                        name: prayer.$2,
                        time: formattedTime,
                        icon: prayer.$3,
                        isNext: isNext,
                        isLast: index == prayers.length - 1,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimeItem({
    required String name,
    required String time,
    required IconData icon,
    required bool isNext,
    required bool isLast,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        border: isNext
            ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
            ),
            child: Icon(
              icon,
              color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.spacingMD),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                color: Colors.white.withValues(alpha: isNext ? 1.0 : 0.85),
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isNext
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
