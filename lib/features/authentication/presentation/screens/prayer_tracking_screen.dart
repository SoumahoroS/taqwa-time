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
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Vérifier si l'utilisateur est connecté
    if (authService.currentUser == null) {
      // Rediriger vers login si pas connecté
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    
    _userId = authService.currentUser!.uid;

    _initialize();

    // Mettre à jour l'interface toutes les minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _updateNextPrayer();
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
    final minutesSinceScheduled = now.difference(scheduledTime).inMinutes;

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

    // Vérifier si la fenêtre de marquage est dépassée (60 minutes max)
    if (minutesSinceScheduled > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Délai dépassé. Impossible de marquer cette prière comme accomplie.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier si c'est le bon moment pour marquer la prière (minimum 2 minutes après l'heure)
    if (minutesSinceScheduled < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vous pouvez marquer cette prière dans ${2 - minutesSinceScheduled} minute(s)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Déterminer le statut selon le délai
    final status = minutesSinceScheduled <= 15
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mes Prières',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des prières...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : _todayPrayers == null || _prayerTimes == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.alert.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur lors du chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez réessayer',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildNextPrayerCard(),
              const SizedBox(height: 8),
              _buildTodaysPrayersCard(),
              const SizedBox(height: 24),
            ],
          ),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prochaine Prière',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CountdownTimer(
                        duration: timeUntil,
                        onFinished: () => _updateNextPrayer(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _markPrayerCompleted(currentPrayer);
                      },
                      icon: const Icon(
                        Icons.check_circle,
                        size: 20,
                      ),
                      label: const Text(
                        'Marquer accomplie',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await _notificationService.createReminderNotification(
                      id: 12345,
                      title: 'Test de notification',
                      body: 'Cette notification est un test',
                      intensityLevel: 2,
                    );
                  },
                  icon: Icon(
                    Icons.notifications_active,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: Text(
                    'Test',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _scheduleNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notifications reprogrammées'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: Text(
                    'Programmer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysPrayersCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Prières du Jour',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_todayPrayers!.where((p) => p.status == PrayerStatus.onTime || p.status == PrayerStatus.late).length}/${_todayPrayers!.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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

    // Déterminer la couleur en fonction du statut et du temps
    Color getBackgroundColor() {
      if (prayer.status == PrayerStatus.onTime) {
        return AppColors.primary.withOpacity(0.1);
      } else if (prayer.status == PrayerStatus.late) {
        return AppColors.accent.withOpacity(0.1);
      } else if (prayer.status == PrayerStatus.missed) {
        return AppColors.alert.withOpacity(0.1);
      } else if (!isFuture) {
        return AppColors.alert.withOpacity(0.05);
      }
      return Colors.grey.withOpacity(0.05);
    }

    Icon getLeadingIcon() {
      switch (prayer.status) {
        case PrayerStatus.onTime:
          return Icon(Icons.check_circle, color: AppColors.primary, size: 28);
        case PrayerStatus.late:
          return Icon(Icons.access_time, color: AppColors.accent, size: 28);
        case PrayerStatus.missed:
          return Icon(Icons.cancel, color: AppColors.alert, size: 28);
        default:
          if (isFuture) {
            return Icon(Icons.schedule, color: Colors.grey[600], size: 28);
          } else {
            return Icon(Icons.radio_button_unchecked, color: AppColors.alert, size: 28);
          }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: getLeadingIcon(),
        ),
        title: Text(
          prayerName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.secondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!isFuture && prayer.status == PrayerStatus.notYet)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'En retard',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.alert,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed)
              _buildMarkCompletedButton(prayer, isFuture),
            if (prayer.status == PrayerStatus.notYet && !isFuture) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.alert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alert.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_active, color: AppColors.alert, size: 18),
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
                      SnackBar(
                        content: const Text('Rappel envoyé'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarkCompletedButton(PrayerModel prayer, bool isFuture) {
    final now = DateTime.now();
    final minutesSinceScheduled = now.difference(prayer.scheduledTime).inMinutes;
    
    // Vérifier si le bouton doit être désactivé
    bool isButtonDisabled = false;
    String? disabledReason;
    
    if (isFuture) {
      isButtonDisabled = true;
      disabledReason = 'Prière future';
    } else if (minutesSinceScheduled < 2) {
      isButtonDisabled = true;
      disabledReason = 'Attendez ${2 - minutesSinceScheduled} min';
    } else if (minutesSinceScheduled > 60) {
      isButtonDisabled = true;
      disabledReason = 'Délai dépassé';
    }

    return Container(
      decoration: BoxDecoration(
        color: isButtonDisabled 
            ? Colors.grey.withOpacity(0.3)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isButtonDisabled ? [] : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.check, 
          color: isButtonDisabled ? Colors.grey : Colors.white, 
          size: 20
        ),
        onPressed: isButtonDisabled 
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(disabledReason!),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            : () => _markPrayerCompleted(prayer),
      ),
    );
  }
}