import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/models/prayer_model.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';
import '../../../../shared/widgets/prayer_widgets/countdown_timer.dart';

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

    if (authService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    _userId = authService.currentUser!.uid;
    _initialize();

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
    setState(() => _isLoading = true);
    try {
      await _calculatePrayerTimes();
      await _loadTodayPrayers();
      await _updateNextPrayer();
      await _scheduleNotifications();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculatePrayerTimes() async {
    final prayerTimes = await _prayerTimeService.getAllPrayerTimes();
    setState(() => _prayerTimes = prayerTimes);
  }

  Future<void> _loadTodayPrayers() async {
    if (_prayerTimes == null) return;
    final today = DateTime.now();
    try {
      final prayers = await _prayerRepository.getUserPrayers(_userId, today).first;
      if (prayers.isEmpty) {
        final newPrayers = await _prayerTimeService.createDailyPrayers(userId: _userId, date: today);
        await _prayerRepository.savePrayers(newPrayers);
        setState(() => _todayPrayers = newPrayers);
      } else {
        setState(() => _todayPrayers = prayers);
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

  Future<void> _scheduleNotifications() async {
    if (_todayPrayers == null || _todayPrayers!.isEmpty) return;
    await _notificationService.cancelAllNotifications();

    for (int i = 0; i < _todayPrayers!.length; i++) {
      final prayer = _todayPrayers![i];
      if (prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed) {
        PrayerModel? nextPrayer;
        String? nextPrayerName;
        DateTime? nextPrayerTime;

        if (i < _todayPrayers!.length - 1) {
          nextPrayer = _todayPrayers![i + 1];
          nextPrayerName = _prayerTimeService.getPrayerName(nextPrayer.type);
          nextPrayerTime = nextPrayer.scheduledTime;
        }

        await _notificationService.schedulePrayerNotificationSequence(
          prayerId: prayer.id,
          prayerType: prayer.type,
          prayerName: _prayerTimeService.getPrayerName(prayer.type),
          scheduledTime: prayer.scheduledTime,
          nextPrayerTime: nextPrayerTime,
          nextPrayerName: nextPrayerName ?? '',
          userId: _userId,
        );
      }
    }

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

    if (now.isBefore(scheduledTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de marquer une prière future comme accomplie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (minutesSinceScheduled > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Délai dépassé. Impossible de marquer cette prière comme accomplie.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (minutesSinceScheduled < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous pouvez marquer cette prière dans ${2 - minutesSinceScheduled} minute(s)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final status = minutesSinceScheduled <= 15 ? PrayerStatus.onTime : PrayerStatus.late;

    try {
      final notificationId = _notificationService.generateNotificationId(prayer.id);
      await _notificationService.cancelNotification(notificationId);
      await _prayerRepository.updatePrayerStatus(prayer.id, status, now);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mes Prières',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTokens.spacingSM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () async {
                setState(() => _isLoading = true);
                await _initialize();
                setState(() => _isLoading = false);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        Text(
                          'Chargement des prières...',
                          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  )
                : _todayPrayers == null || _prayerTimes == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: AppColors.alertLight.withValues(alpha: 0.8)),
                            const SizedBox(height: AppTokens.spacingMD),
                            const Text(
                              'Erreur lors du chargement',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const SizedBox(height: AppTokens.spacingSM),
                            Text(
                              'Veuillez réessayer',
                              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMD),
                          child: Column(
                            children: [
                              const SizedBox(height: AppTokens.spacingMD),
                              _buildNextPrayerCard(),
                              const SizedBox(height: AppTokens.spacingSM),
                              _buildTodaysPrayersCard(),
                              const SizedBox(height: AppTokens.spacingLG),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
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

    final currentPrayer = _todayPrayers!.firstWhere(
      (p) => p.type == _nextPrayerType,
      orElse: () => _todayPrayers!.first,
    );

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.spacingSM),
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      tintColor: AppColors.primary.withValues(alpha: 0.15),
      borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: AppTokens.spacingSM),
              Text(
                'Prochaine Prière',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingLG),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(prayerName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: AppTokens.spacingXS),
                  Text(formattedTime, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: AppTokens.spacingSM),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSM, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CountdownTimer(duration: timeUntil, onFinished: () => _updateNextPrayer()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLG),
          GlassButton(
            label: 'Marquer accomplie',
            icon: Icons.check_circle,
            onPressed: () => _markPrayerCompleted(currentPrayer),
            variant: GlassButtonVariant.primary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPrayersCard() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.spacingSM),
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSM),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                ),
                child: const Icon(Icons.today, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTokens.spacingSM),
              const Text(
                'Prières du Jour',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSM, vertical: AppTokens.spacingXS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                ),
                child: Text(
                  '${_todayPrayers!.where((p) => p.status == PrayerStatus.onTime || p.status == PrayerStatus.late).length}/${_todayPrayers!.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingLG),
          ..._todayPrayers!.map((prayer) => _buildPrayerItem(prayer)),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(PrayerModel prayer) {
    final prayerName = _prayerTimeService.getPrayerName(prayer.type);
    final formattedTime = _prayerTimeService.formatPrayerTime(prayer.scheduledTime);
    final now = DateTime.now();
    final isFuture = prayer.scheduledTime.isAfter(now);

    Color getBackgroundColor() {
      if (prayer.status == PrayerStatus.onTime) return AppColors.primary.withValues(alpha: 0.2);
      if (prayer.status == PrayerStatus.late) return AppColors.accent.withValues(alpha: 0.2);
      if (prayer.status == PrayerStatus.missed) return AppColors.alert.withValues(alpha: 0.2);
      if (!isFuture) return AppColors.alert.withValues(alpha: 0.1);
      return Colors.white.withValues(alpha: 0.08);
    }

    Icon getLeadingIcon() {
      switch (prayer.status) {
        case PrayerStatus.onTime:
          return const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 28);
        case PrayerStatus.late:
          return const Icon(Icons.access_time, color: AppColors.accentLight, size: 28);
        case PrayerStatus.missed:
          return const Icon(Icons.cancel, color: AppColors.alertLight, size: 28);
        case PrayerStatus.notYet:
          if (isFuture) {
            return Icon(Icons.schedule, color: Colors.white.withValues(alpha: 0.5), size: 28);
          } else {
            return const Icon(Icons.radio_button_unchecked, color: AppColors.alertLight, size: 28);
          }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSM),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMD, vertical: AppTokens.spacingSM),
        leading: Container(
          padding: const EdgeInsets.all(AppTokens.spacingSM),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: getLeadingIcon(),
        ),
        title: Text(prayerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTokens.spacingXS),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: AppTokens.spacingXS),
                Text(formattedTime, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
              ],
            ),
            if (!isFuture && prayer.status == PrayerStatus.notYet)
              const Padding(
                padding: EdgeInsets.only(top: AppTokens.spacingXS),
                child: Text('En retard', style: TextStyle(fontSize: 12, color: AppColors.alertLight, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prayer.status == PrayerStatus.notYet || prayer.status == PrayerStatus.missed)
              _buildMarkCompletedButton(prayer, isFuture),
            if (prayer.status == PrayerStatus.notYet && !isFuture) ...[
              const SizedBox(width: AppTokens.spacingSM),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  border: Border.all(color: AppColors.alertLight.withValues(alpha: 0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_active, color: AppColors.alertLight, size: 18),
                  onPressed: () async {
                    final notificationId = _notificationService.generateNotificationId(prayer.id);
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
        border: Border.all(
          color: isButtonDisabled
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.primaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.check,
          color: isButtonDisabled ? Colors.white.withValues(alpha: 0.3) : Colors.white,
          size: 20,
        ),
        onPressed: isButtonDisabled
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(disabledReason!),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            : () => _markPrayerCompleted(prayer),
      ),
    );
  }
}
