import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'features/authentication/presentation/screens/auth_wrapper.dart';
import 'features/prayer_notification/presentation/screens/fullscreen_prayer_alert.dart';
import 'routes.dart';
import 'shared/themes/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/prayer_repository.dart';
import 'core/models/prayer_model.dart';
import 'main.dart' show globalNotificationService, onNotificationActionReceived;

// Définir cette méthode en dehors de la classe pour qu'elle puisse être utilisée comme une fonction statique
@pragma('vm:entry-point')
Future<void> appActionReceivedMethod(ReceivedAction receivedAction) async {
  print("🔔 Action de notification reçue dans app.dart: ${receivedAction.buttonKeyPressed}");

  // Extraire les informations importantes de la notification
  final int notificationId = receivedAction.id ?? 0;
  final String buttonKey = receivedAction.buttonKeyPressed ?? '';
  final String title = receivedAction.title ?? 'Rappel de prière';

  // S'assurer que le service de notification est disponible
  if (globalNotificationService == null) {
    print("⚠️ Service de notification non disponible");
    return;
  }

  if (buttonKey == 'MARK_DONE') {
    // L'utilisateur a marqué la prière comme accomplie
    print('✅ Prière marquée comme accomplie depuis la notification (app.dart)');

    // Arrêter tous les rappels
    await globalNotificationService!.resetReminderCount(notificationId);

    // Annuler la notification
    await globalNotificationService!.cancelNotification(notificationId);
  } else if (buttonKey == 'REMIND_LATER') {
    // L'utilisateur a demandé un rappel ultérieur
    print('⏰ Rappel ultérieur demandé depuis la notification (app.dart)');

    // Activer les rappels automatiques et programmer le prochain rappel
    await globalNotificationService!.scheduleNextReminder(notificationId, title);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Configuration des notifications
    _setupNotifications();
    // Configuration du gestionnaire de notifications en premier plan
    _setupInAppNotificationHandler();
    print("📱 App initialisée avec notifications");
  }

  Future<void> _setupNotifications() async {
    // Les écouteurs principaux sont configurés dans main.dart
    print("🔔 Service de notification: utilisation de la configuration globale de main.dart");
  }

  Future<void> _setupInAppNotificationHandler() async {
    // Cette méthode permet de gérer les notifications lorsque l'application est au premier plan
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onNotificationActionReceived,  // Utiliser la méthode globale de main.dart
      onNotificationDisplayedMethod: (receivedNotification) async {
        print("📲 Notification affichée en premier plan: ${receivedNotification.title}");

        // Récupérer le context du navigateur global
        final context = navigatorKey.currentContext;
        if (context == null) {
          print("⚠️ Contexte non disponible pour afficher l'alerte plein écran");
          return;
        }

        // Si l'application est ouverte, montrer l'alerte plein écran pour les rappels
        if (receivedNotification.channelKey == 'reminder_channel') {
          try {
            print("🔍 Traitement de la notification de rappel en premier plan");

            // Obtenir le service de notification et le repository
            final notificationService = Provider.of<NotificationService>(context, listen: false);
            final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);

            // Extraire les données de la notification
            final int notificationId = receivedNotification.id ?? 0;
            final String prayerId = receivedNotification.payload?['prayer_id'] ?? '';
            final String prayerTypeName = receivedNotification.payload?['prayer_type'] ?? '';

            print("📋 Données de notification - ID: $notificationId, PrièreID: $prayerId, Type: $prayerTypeName");

            // Corriger l'utilisation de replace par replaceAll
            final String prayerName = receivedNotification.title?.replaceAll('Rappel:', '').trim() ?? 'Prière';

            // Convertir le nom du type en enum si nécessaire
            PrayerType? prayerType;
            try {
              if (prayerTypeName.isNotEmpty) {
                prayerType = PrayerType.values.firstWhere(
                        (type) => type.name == prayerTypeName
                );
              }
            } catch (e) {
              print('⚠️ Type de prière non reconnu: $prayerTypeName');
            }

            // Obtenir l'heure programmée de la prière
            DateTime scheduledTime = DateTime.now();
            if (prayerId.isNotEmpty) {
              final prayer = await prayerRepository.getPrayerById(prayerId);
              if (prayer != null) {
                prayerType = prayer.type;
                scheduledTime = prayer.scheduledTime;
                print("📅 Heure de prière récupérée: ${scheduledTime.toString()}");
              } else {
                print("⚠️ Prière non trouvée dans la base de données");
              }
            }

            // Obtenir le compteur de rappels
            final reminderCount = await notificationService.getReminderCount(notificationId);
            print("🔢 Compteur de rappels: $reminderCount");

            // Afficher l'alerte plein écran
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => FullscreenPrayerAlert(
                  prayerName: prayerName,
                  scheduledTime: scheduledTime,
                  reminderCount: reminderCount,
                  maxReminders: NotificationService.MAX_REMINDERS,
                  onPrayerCompleted: () async {
                    print("✅ Prière marquée comme accomplie depuis l'alerte plein écran");
                    // Marquer la prière comme accomplie
                    await notificationService.resetReminderCount(notificationId);
                    Navigator.of(context).pop(); // Fermer l'écran

                    // Afficher une confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Prière $prayerName marquée comme accomplie'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onRemindLater: () async {
                    print("⏰ Rappel demandé depuis l'alerte plein écran");
                    // Programmer le prochain rappel
                    await notificationService.scheduleNextReminder(notificationId, 'Rappel: $prayerName');

                    Navigator.of(context).pop(); // Fermer l'écran
                  },
                ),
              ),
            );
            print("📱 Alerte plein écran affichée avec succès");
          } catch (e) {
            print('❌ ERREUR lors de l\'affichage de l\'alerte: $e');
          }
        }
      },
      onNotificationCreatedMethod: (receivedNotification) async {
        print('📝 Notification créée (in-app): ${receivedNotification.title}');
      },
      onDismissActionReceivedMethod: (receivedAction) async {
        print('🗑️ Notification ignorée (in-app)');
      },
    );
    print("👂 Gestionnaire de notifications en premier plan configuré");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Ajouter la clé de navigateur
      title: 'TaqwaTime',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: AuthWrapper(),
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page non trouvée'),
            ),
            body: Center(
              child: Text('La page "${settings.name}" n\'existe pas.'),
            ),
          ),
        );
      },
    );
  }
}