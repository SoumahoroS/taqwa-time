import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/models/prayer_model.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/repositories/prayer_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/themes/app_colors.dart';

class PrayerNotificationScreen extends StatefulWidget {
  final PrayerType prayerType;
  final DateTime scheduledTime;
  final String prayerId;
  final int reminderCount;

  const PrayerNotificationScreen({
    Key? key,
    required this.prayerType,
    required this.scheduledTime,
    required this.prayerId,
    this.reminderCount = 0,
  }) : super(key: key);

  @override
  _PrayerNotificationScreenState createState() => _PrayerNotificationScreenState();
}

class _PrayerNotificationScreenState extends State<PrayerNotificationScreen> with SingleTickerProviderStateMixin {
  late PrayerTimeService _prayerTimeService;
  late PrayerRepository _prayerRepository;
  late NotificationService _notificationService;
  bool _isConfirming = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _vibrationTimer;
  int _intensityLevel = 1;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);

    // Initialiser l'animation pulsante
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    // Définir le niveau d'intensité en fonction du nombre de rappels
    _intensityLevel = widget.reminderCount > 0 ? widget.reminderCount : 1;

    // Si c'est un rappel de niveau élevé, ajouter des vibrations périodiques
    if (_intensityLevel > 1) {
      // Vibration périodique qui s'intensifie avec le niveau
      _startPeriodicVibration();
    }
  }

  void _startPeriodicVibration() {
    // Simuler des vibrations périodiques avec un intervalle qui diminue avec l'intensité
    final interval = _intensityLevel <= 3 ? 2000 : 1000;
    _vibrationTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      // Dans une vraie application, vous utiliseriez le plugin de vibration ici
      // Par exemple: Vibration.vibrate(duration: 200 * _intensityLevel);
      print('Vibration avec intensité: $_intensityLevel');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmPrayer() async {
    setState(() {
      _isConfirming = true;
    });

    try {
      final now = DateTime.now();
      final status = now.difference(widget.scheduledTime).inMinutes < 15
          ? PrayerStatus.onTime
          : PrayerStatus.late;

      // Générer un ID de notification basé sur l'ID de la prière
      final notificationId = int.parse(
          widget.prayerId.hashCode.toString().substring(0, 8).replaceAll('-', '1')
      );

      // Annuler toute notification pour cette prière
      await _notificationService.cancelNotification(notificationId);

      await _prayerRepository.updatePrayerStatus(
        widget.prayerId,
        status,
        now,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isConfirming = false;
      });
    }
  }

  Future<void> _remindLater() async {
    // Générer un ID de notification basé sur l'ID de la prière
    final notificationId = int.parse(
        widget.prayerId.hashCode.toString().substring(0, 8).replaceAll('-', '1')
    );

    // Programmer un rappel avec une intensité accrue
    await _notificationService.createReminderNotification(
      id: notificationId,
      title: 'Rappel: ${_prayerTimeService.getPrayerName(widget.prayerType)}',
      body: 'N\'oubliez pas votre prière !',
      intensityLevel: _intensityLevel + 1,
      delayMinutes: _intensityLevel > 3 ? 2 : 5, // Intervalles plus courts avec l'intensité
    );

    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final prayerName = _prayerTimeService.getPrayerName(widget.prayerType);
    final formattedTime = _prayerTimeService.formatPrayerTime(widget.scheduledTime);

    // Couleur de l'écran qui s'intensifie avec le niveau de rappel
    Color backgroundColor = AppColors.alert.withOpacity(0.7 + (_intensityLevel * 0.05));
    if (_intensityLevel > 3) backgroundColor = AppColors.alert;

    // Texte d'urgence pour les niveaux élevés
    String urgencyText = '';
    if (_intensityLevel > 1) {
      urgencyText = 'URGENT ! ';
      for (int i = 0; i < _intensityLevel; i++) {
        urgencyText += '!';
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Titre avec urgence croissante
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _intensityLevel > 1 ? _pulseAnimation.value : 1.0,
                    child: Text(
                      _intensityLevel > 1 ? '$urgencyText\nHeure de la Prière' : 'Heure de la Prière',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24 + (_intensityLevel * 1.5), // Taille qui augmente avec l'intensité
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              SizedBox(height: 40),

              // Horloge de prière
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: _intensityLevel > 1
                            ? Colors.red.withOpacity(_pulseAnimation.value - 0.5)
                            : Colors.transparent,
                        width: _intensityLevel > 1 ? 3.0 : 0.0,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _intensityLevel > 2 ? Icons.alarm_on : Icons.access_time,
                            size: 40,
                            color: _intensityLevel > 2 ? Colors.red : AppColors.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            prayerName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _intensityLevel > 2 ? Colors.red : AppColors.primary,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 40),

              // Message d'urgence pour les niveaux élevés
              if (_intensityLevel > 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Cette prière est en attente depuis longtemps !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: 20),

              // Bouton de confirmation
              SizedBox(
                width: 240,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isConfirming ? null : _confirmPrayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _intensityLevel > 2 ? Colors.red : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: _isConfirming
                      ? CircularProgressIndicator(color: AppColors.primary)
                      : Text(
                    'Confirmer la prière',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Bouton de rappel (qui devient de plus en plus petit avec l'intensité)
              SizedBox(
                width: 240 - (_intensityLevel * 20), // Rétrécit avec l'intensité
                child: TextButton(
                  onPressed: _remindLater,
                  child: Text(
                    _intensityLevel > 2
                        ? 'Rappel court'
                        : 'Me rappeler dans 5 minutes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Spacer(),

              // Visualisation du calendrier de constance
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _intensityLevel > 2
                      ? 'Ne manquez pas cette prière !'
                      : 'Continuez à maintenir votre régularité !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}