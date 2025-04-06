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
      _updateNextPrayer();
      _loadTodayPrayers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaqwaTime'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initialize();
            },
          ),
        ],
      ),
      drawer: TaqwaTimeDrawer(currentUser: _currentUser),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // En-tête de bienvenue avec le nom d'utilisateur
            if (_currentUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.grey[100],
                child: Text(
                  'Salam, ${_currentUser!.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNextPrayerSection(),
                    const SizedBox(height: 24),
                    _buildPerformanceSection(),
                    const SizedBox(height: 24),
                    _buildPrayerTimesSection(),
                  ],
                ),
              ),
            ),
            BottomNavigation(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
                // Navigation basée sur l'index
                switch (index) {
                  case 0:
                  // Déjà sur l'écran d'accueil
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/prayer-tracking');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/quran');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/statistics');
                    break;
                }
              },
            ),
          ],
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