import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/models/prayer_model.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/widgets/prayer_widgets/countdown_timer.dart';
import '../../../../shared/widgets/status/prayer_status_indicator.dart';

class PrayerTrackingScreen extends StatefulWidget {
  const PrayerTrackingScreen({Key? key}) : super(key: key);

  @override
  _PrayerTrackingScreenState createState() => _PrayerTrackingScreenState();
}

class _PrayerTrackingScreenState extends State<PrayerTrackingScreen> {
  late PrayerTimeService _prayerTimeService;
  late PrayerRepository _prayerRepository;
  late NotificationService _notificationService;
  late String _userId;

  Map<PrayerType, DateTime>? _prayerTimes;
  List<PrayerModel>? _todayPrayers;
  PrayerType? _nextPrayerType;
  DateTime? _nextPrayerTime;
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    _userId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;

    _initialize();

    // Mettre à jour l'interface toutes les minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateNextPrayer();
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
      await _calculatePrayerTimes();
      await _loadTodayPrayers();
      await _updateNextPrayer();
      await _scheduleNotifications();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePrayerTimes() async {
    final prayerTimes = await _prayerTimeService.getAllPrayerTimes();

    setState(() {
      _prayerTimes = prayerTimes;
    });
  }

  Future<void> _loadTodayPrayers() async {
    if (_prayerTimes == null) return;

    final today = DateTime.now();

    try {
      // Vérifier si les prières existent déjà pour aujourd'hui
      final prayers = await _prayerRepository
          .getUserPrayers(_userId, today)
          .first;

      if (prayers.isEmpty) {
        // Créer les prières pour aujourd'hui
        final newPrayers = await _prayerTimeService.createDailyPrayers(
          userId: _userId,
          date: today,
        );

        await _prayerRepository.savePrayers(newPrayers);
        setState(() {
          _todayPrayers = newPrayers;
        });
      } else {
        setState(() {
          _todayPrayers = prayers;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des prières: $e');
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

  Future<void> _scheduleNotificationsLite() async {
    if (_todayPrayers == null || _todayPrayers!.isEmpty) return;

    // Annuler toutes les notifications précédentes
    await _notificationService.cancelAllNotifications();

    // Programmer des notifications pour toutes les prières qui n'ont pas encore été accomplies
    final now = DateTime.now();

    for (var prayer in _todayPrayers!) {
      // Ne programmer des notifications que pour les prières futures ou celles qui ne sont pas encore accomplies
      if ((prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed) &&
          prayer.scheduledTime.isAfter(now.subtract(const Duration(hours: 1)))) {

        // Générer un ID unique pour la notification
        final notificationId = int.parse(
            prayer.id.hashCode.toString().substring(0, 8).replaceAll('-', '1')
        );

        final title = 'Heure de la prière';
        final body = 'C\'est l\'heure de ${_prayerTimeService.getPrayerName(prayer.type)} (${_prayerTimeService.formatPrayerTime(prayer.scheduledTime)})';

        await _notificationService.schedulePrayerNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledTime: prayer.scheduledTime,
          vibration: true,
        );
      }
    }
  }


  Future<void> _scheduleNotifications() async {
    if (_todayPrayers == null || _todayPrayers!.isEmpty) return;

    // Annuler toutes les notifications précédentes
    await _notificationService.cancelAllNotifications();

    // Programmer des notifications pour toutes les prières
    final now = DateTime.now();

    for (int i = 0; i < _todayPrayers!.length; i++) {
      final prayer = _todayPrayers![i];

      // Ne programmer des notifications que pour les prières qui ne sont pas encore accomplies
      if (prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed) {

        // Déterminer la prochaine prière (pour les notifications de transition)
        PrayerModel? nextPrayer;
        String? nextPrayerName;
        DateTime? nextPrayerTime;

        if (i < _todayPrayers!.length - 1) {
          nextPrayer = _todayPrayers![i + 1];
          nextPrayerName = _prayerTimeService.getPrayerName(nextPrayer.type);
          nextPrayerTime = nextPrayer.scheduledTime;
        } else {
          // Si c'est la dernière prière du jour, laisser ces valeurs nulles
          // ou calculer la première prière du lendemain si nécessaire
        }

        // Programmer la séquence complète de notifications pour cette prière
        await _notificationService.schedulePrayerNotificationSequence(
          prayerId: prayer.id,
          prayerType: prayer.type,
          prayerName: _prayerTimeService.getPrayerName(prayer.type),
          scheduledTime: prayer.scheduledTime,
          nextPrayerTime: nextPrayerTime,
          nextPrayerName: nextPrayerName ?? '',
        );
      }
    }

    // Afficher une confirmation à l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications programmées pour toutes les prières'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _markPrayerCompleted(PrayerModel prayer) async {
    final now = DateTime.now();
    final scheduledTime = prayer.scheduledTime;

    // Vérifier si la prière est future
    if (now.isBefore(scheduledTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de marquer une prière future comme accomplie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Déterminer si la prière est à l'heure ou en retard
    final status = now.difference(scheduledTime).inMinutes < 15
        ? PrayerStatus.onTime
        : PrayerStatus.late;

    try {
      // Générer un ID de notification basé sur l'ID de la prière
      final notificationId = int.parse(
          prayer.id.hashCode.toString().substring(0, 8).replaceAll('-', '1')
      );

      // Annuler toute notification pour cette prière
      await _notificationService.cancelNotification(notificationId);

      // Mettre à jour le statut de la prière
      await _prayerRepository.updatePrayerStatus(
        prayer.id,
        status,
        now,
      );

      // Recharger les prières
      await _loadTodayPrayers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prière ${_prayerTimeService.getPrayerName(prayer.type)} accomplie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors du marquage de la prière comme complétée: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Prières'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _initialize();
              setState(() {
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todayPrayers == null || _prayerTimes == null
          ? const Center(child: Text('Erreur lors du chargement des prières'))
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildNextPrayerCard(),
            _buildTodaysPrayersCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    if (_nextPrayerTime == null || _nextPrayerType == null) {
      return const SizedBox.shrink();
    }

    final prayerName = _prayerTimeService.getPrayerName(_nextPrayerType!);
    final formattedTime = _prayerTimeService.formatPrayerTime(_nextPrayerTime!);
    final timeUntil = _prayerTimeService.timeUntilNextPrayer(_nextPrayerTime!);

    // Trouver la prière correspondante dans la liste
    final currentPrayer = _todayPrayers!.firstWhere(
          (p) => p.type == _nextPrayerType,
      orElse: () => _todayPrayers!.first,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Prochaine Prière',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      prayerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CountdownTimer(
                      duration: timeUntil,
                      onFinished: () => _updateNextPrayer(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _notificationService.createReminderNotification(
                  id: 12345,
                  title: 'Test de notification',
                  body: 'Cette notification est un test',
                  intensityLevel: 2,
                );
              },
              child: Text('Tester notification'),
            ),
            ElevatedButton(
              onPressed: () {
                _markPrayerCompleted(currentPrayer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Marquer comme accomplie',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),

              ),
            ),
            TextButton(
              onPressed: () {
                _scheduleNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications reprogrammées'),
                    backgroundColor: Colors.blue,

                  ),
                );
              },
              child: const Text('Reprogrammer les rappels'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysPrayersCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prières du Jour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._todayPrayers!.map((prayer) => _buildPrayerItem(prayer)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerItem(PrayerModel prayer) {
    final prayerName = _prayerTimeService.getPrayerName(prayer.type);
    final formattedTime = _prayerTimeService.formatPrayerTime(prayer.scheduledTime);

    // Vérifier si la prière est future
    final now = DateTime.now();
    final isFuture = prayer.scheduledTime.isAfter(now);

    return ListTile(
      title: Text(
        prayerName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(formattedTime),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrayerStatusIndicator(status: prayer.status),
          if (prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.primary,
              onPressed: isFuture
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible de marquer une prière future comme accomplie'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
                  : () => _markPrayerCompleted(prayer),
            ),
          if (prayer.status == PrayerStatus.notYet && !isFuture)
            IconButton(
              icon: const Icon(Icons.alarm),
              color: AppColors.alert,
              onPressed: () async {
                // Générer l'ID de notification pour cette prière
                final notificationId = int.parse(
                    prayer.id.hashCode.toString().substring(0, 8).replaceAll('-', '1')
                );

                // Créer un rappel immédiat avec une intensité moyenne
                await _notificationService.createReminderNotification(
                  id: notificationId,
                  title: 'Rappel urgent: ${_prayerTimeService.getPrayerName(prayer.type)}',
                  body: 'Cette prière n\'a pas encore été accomplie !',
                  intensityLevel: 2,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rappel envoyé'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}