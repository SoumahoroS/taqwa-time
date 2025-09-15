import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/themes/app_colors.dart';

class FullscreenPrayerAlert extends StatelessWidget {
  final String prayerName;
  final DateTime scheduledTime;
  final int reminderCount;
  final int maxReminders;
  final VoidCallback onPrayerCompleted;
  final VoidCallback onRemindLater;

  const FullscreenPrayerAlert({
    Key? key,
    required this.prayerName,
    required this.scheduledTime,
    required this.reminderCount,
    required this.maxReminders,
    required this.onPrayerCompleted,
    required this.onRemindLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final timeFormat = DateFormat('HH:mm');
    final isUrgent = reminderCount > 2;

    return Scaffold(
      backgroundColor: isUrgent ? AppColors.alert.withOpacity(0.95) : AppColors.primary.withOpacity(0.95),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isUrgent 
                ? [
                    AppColors.alert.withOpacity(0.9),
                    AppColors.alert.withOpacity(0.7),
                    AppColors.primary.withOpacity(0.8),
                  ]
                : [
                    AppColors.primary.withOpacity(0.9),
                    AppColors.secondary.withOpacity(0.7),
                    AppColors.primary.withOpacity(0.8),
                  ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation d'alerte
              if (isUrgent)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      reminderCount,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '⚠️',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),

              // Icône de prière
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.mosque,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Titre principal
              Text(
                'Heure de la prière',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Nom de la prière
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Heure programmée
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Text(
                  timeFormat.format(scheduledTime),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Compteur de rappels
              if (reminderCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.3),
                  ),
                  child: Text(
                    'Rappel ${reminderCount}/${maxReminders}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Message d'encouragement
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isUrgent
                    ? 'Cette prière est importante !\nNe la manquez pas.'
                    : 'Prenez un moment pour vous connecter\navec Allah.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 50),

              // Boutons d'action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // Bouton principal - Prière accomplie
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: onPrayerCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          '✅ Prière accomplie',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Bouton secondaire - Rappeler plus tard
                    if (reminderCount < maxReminders)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: onRemindLater,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            '⏰ Rappeler dans 5 min',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Indication de fermeture
              Text(
                'Glissez vers le bas pour ignorer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}