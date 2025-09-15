// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/models/prayer_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/widgets/navigation/bottom_navigation.dart';
import '../../../../shared/widgets/navigation/taqwa_time_drawer.dart';
import '../../../../shared/widgets/cards/next_prayer_card.dart';
import '../../../../shared/widgets/cards/prayer_times_card.dart';
import '../../../../shared/widgets/cards/prayer_performance_widget.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PrayerTimeService _prayerTimeService;
  late AuthService _authService;
  late PrayerRepository _prayerRepository;

  Map<PrayerType, DateTime>? _prayerTimes;
  Map<PrayerType, PrayerStatus> _prayerStatuses = {};
  List<PrayerModel>? _todayPrayers;
  Map<String, dynamic>? _prayerStats;
  PrayerType? _nextPrayerType;
  DateTime? _nextPrayerTime;
  Timer? _refreshTimer;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  UserModel? _currentUser;
  int _streak = 0;
  double _weeklyCompletion = 0.0;
  String _trend = 'stable';

  @override
  void initState() {
    super.initState();
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    _initialize();

    // Mettre à jour l'interface toutes les minutes
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
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur connecté
      await _loadCurrentUser();

      // Charger les horaires de prière
      await _loadPrayerTimes();

      // Charger les prières d'aujourd'hui pour connaître leur statut
      await _loadTodayPrayers();

      // Charger les statistiques des prières
      await _loadPrayerStats();

      // Déterminer la prochaine prière
      await _updateNextPrayer();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final user = _authService.currentUser;

      if (user != null) {
        // Obtenir les données utilisateur complètes depuis Firestore
        final userData = await _authService.getUserData(user.uid);

        setState(() {
          _currentUser = userData;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayerTimes = await _prayerTimeService.getAllPrayerTimes();

    setState(() {
      _prayerTimes = prayerTimes;
    });
  }

  Future<void> _loadTodayPrayers() async {
    if (_authService.currentUser == null) return;
    
    // Si l'utilisateur est un invité, ne pas charger les prières personnalisées
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

        setState(() {
          _todayPrayers = prayers;
          _prayerStatuses = statuses;
        });
      } else {
        // Si pas de prières, en créer pour aujourd'hui
        final newPrayers = await _prayerTimeService.createDailyPrayers(
          userId: userId,
          date: today,
        );

        Map<PrayerType, PrayerStatus> statuses = {};
        for (var prayer in newPrayers) {
          statuses[prayer.type] = prayer.status;
        }

        await _prayerRepository.savePrayers(newPrayers);
        setState(() {
          _todayPrayers = newPrayers;
          _prayerStatuses = statuses;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des prières: $e');
    }
  }

  Future<void> _loadPrayerStats() async {
    if (_authService.currentUser == null) return;
    
    // Si l'utilisateur est un invité, ne pas charger les statistiques personnalisées
    if (_authService.isGuestUser) return;

    final userId = _authService.currentUser!.uid;

    try {
      // Récupérer les statistiques des 7 derniers jours
      final stats = await _prayerRepository.getUserPrayerStats(userId, 7);

      setState(() {
        _prayerStats = stats;
        _streak = stats['currentStreak'] ?? 0;
        _trend = stats['trend'] ?? 'stable';

        // Calculer le pourcentage de complétion hebdomadaire
        int total = stats['total'] ?? 0;
        int completed = (stats['onTime'] ?? 0) + (stats['late'] ?? 0);

        _weeklyCompletion = total > 0 ? (completed / total) * 100 : 0;
      });

      // Si le streak actuel est meilleur que le précédent, mettre à jour le meilleur streak
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

  Map<PrayerType, bool> _getPrayedStatuses() {
    final Map<PrayerType, bool> statuses = {};

    if (_prayerTimes != null) {
      final now = DateTime.now();

      for (var type in PrayerType.values) {
        final prayerTime = _prayerTimes![type];
        if (prayerTime != null) {
          statuses[type] = now.isAfter(prayerTime) &&
              (type != _nextPrayerType || now.isAfter(_nextPrayerTime!));
        } else {
          statuses[type] = false;
        }
      }
    }

    return statuses;
  }

  void _navigateToStatistics() {
    if (_authService.currentUser == null) {
      // Utilisateur non connecté - rediriger vers login
      Navigator.pushNamed(context, '/login');
    } else {
      // Utilisateur connecté - accéder aux statistiques
      Navigator.pushNamed(context, '/statistics');
    }
  }

  void _navigateToPrayerTracking() {
    if (_authService.currentUser == null) {
      // Utilisateur non connecté - rediriger vers login
      Navigator.pushNamed(context, '/login');
    } else {
      // Utilisateur connecté - accéder au suivi des prières
      Navigator.pushNamed(context, '/prayer-tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'TaqwaTime',
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
              onPressed: () {
                _initialize();
              },
            ),
          ),
        ],
      ),
      drawer: TaqwaTimeDrawer(currentUser: _currentUser),
      body: _isLoading
          ? Container(
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
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Container(
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
                child: Column(
                  children: [
                    // En-tête moderne avec gradient
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
                            child: Icon(
                              _authService.isGuestUser ? Icons.person_outline : Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assalamu Alaikum',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _authService.isGuestUser
                                      ? 'Invité'
                                      : _currentUser?.name ?? 'Utilisateur',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_authService.isGuestUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${_streak}🔥',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

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
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          child: Column(
                            children: [
                              _buildNextPrayerSection(),
                              const SizedBox(height: 32),
                              _buildPerformanceSection(),
                              const SizedBox(height: 32),
                              _buildPrayerTimesSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() {
                _currentNavIndex = index;
              });
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
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerSection() {
    if (_nextPrayerTime == null || _nextPrayerType == null || _prayerTimes == null) {
      return const SizedBox.shrink();
    }

    final prayerName = _prayerTimeService.getPrayerName(_nextPrayerType!);
    final formattedTime = _prayerTimeService.formatPrayerTime(_nextPrayerTime!);
    final timeUntil = _prayerTimeService.timeUntilNextPrayer(_nextPrayerTime!);

    return NextPrayerCard(
      prayerName: prayerName,
      formattedTime: formattedTime,
      timeUntil: timeUntil,
      onTimerFinished: _updateNextPrayer,
      prayerTimes: _prayerTimes!,
      prayedStatus: _getPrayedStatuses(),
      prayerStatuses: _prayerStatuses,
      prayerTimeService: _prayerTimeService,
    );
  }

  Widget _buildPerformanceSection() {
    return PrayerPerformanceWidget(
      prayerStatuses: _prayerStatuses,
      streak: _streak,
      weeklyCompletion: _weeklyCompletion,
      trend: _trend,
    );
  }

  Widget _buildPrayerTimesSection() {
    if (_prayerTimes == null) {
      return const SizedBox.shrink();
    }

    return PrayerTimesCard(
      prayerTimes: _prayerTimes!,
      nextPrayerType: _nextPrayerType,
      prayerTimeService: _prayerTimeService,
    );
  }
}