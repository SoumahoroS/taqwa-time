import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/repositories/settings_repository.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/prayer_time_service.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/prayer_repository.dart';

// Cette variable sera accessible dans toute l'application
NotificationService? globalNotificationService;

// Méthode statique globale pour gérer les actions de notification
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  // Traiter les actions de notification
  if (receivedAction.buttonKeyPressed == 'MARK_DONE') {
    // L'utilisateur a marqué la prière comme accomplie
    print('Prière marquée comme accomplie depuis la notification');

    // Si le service de notification global est disponible, réinitialiser le compteur de rappels
    if (globalNotificationService != null) {
      // Vous devrez exposer une méthode publique pour réinitialiser le compteur
      // globalNotificationService.resetReminderCount(receivedAction.id!);
    }
  } else if (receivedAction.buttonKeyPressed == 'REMIND_LATER') {
    // L'utilisateur a demandé un rappel
    print('Rappel demandé depuis la notification');

    // Si le service de notification global est disponible, programmer le prochain rappel
    if (globalNotificationService != null) {
      // Vous devrez exposer une méthode publique pour programmer le prochain rappel
      // globalNotificationService.scheduleNextReminder(receivedAction.id!, receivedAction.title ?? 'Rappel de prière');
    }
  }
}

// Fonction pour initialiser les écouteurs d'actions
void initializeNotificationActionListeners() {
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onNotificationActionReceived,
  );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser et stocker le service de notification globalement
  globalNotificationService = NotificationService();
  await globalNotificationService!.init();

  // Configurer le gestionnaire d'actions de notification avec une référence à une méthode statique
  initializeNotificationActionListeners();


  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<PrayerTimeService>(
          create: (_) => PrayerTimeService(),
        ),
        Provider<NotificationService>(
          create: (_) => globalNotificationService!,
        ),
        Provider<PrayerRepository>(
          create: (_) => PrayerRepository(),
        ),
        Provider<SettingsRepository>(
          create: (_) => SettingsRepository(),
        ),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MyApp(),
    ),
  );
}