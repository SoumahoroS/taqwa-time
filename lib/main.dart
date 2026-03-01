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
import 'core/services/cache_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/realtime_prayer_service.dart';
import 'core/repositories/prayer_repository.dart';

// Cette variable sera accessible dans toute l'application
NotificationService? globalNotificationService;

// Methode statique globale pour gerer les actions de notification
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'MARK_DONE') {
    if (globalNotificationService != null && receivedAction.id != null) {
      await globalNotificationService!.resetReminderCount(receivedAction.id!);
      await globalNotificationService!.cancelNotification(receivedAction.id!);
    }
  } else if (receivedAction.buttonKeyPressed == 'REMIND_LATER') {
    if (globalNotificationService != null && receivedAction.id != null) {
      await globalNotificationService!.scheduleNextReminder(
        receivedAction.id!,
        receivedAction.title ?? 'Rappel de priere',
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser les services de cache et performance
  await CacheService.instance.init();
  await PerformanceService().initialize();

  // Creer les services et repositories
  final settingsRepository = SettingsRepository();
  final authService = AuthService();

  // Initialiser le service de theme
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialiser le service de notification
  globalNotificationService = NotificationService(settingsRepository);
  await globalNotificationService!.init();

  // Initialiser le service temps reel avec ses dependances
  final realtimePrayerService = RealtimePrayerService();
  realtimePrayerService.initialize(
    authService: authService,
    settingsRepository: settingsRepository,
  );

  // Demarrer le service temps reel et programmer les notifications
  // quand l'utilisateur est connecte
  _startRealtimeServiceWhenReady(authService, realtimePrayerService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(
          create: (_) => themeService,
        ),
        Provider<AuthService>(
          create: (_) => authService,
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
          create: (_) => settingsRepository,
        ),
        Provider<RealtimePrayerService>(
          create: (_) => realtimePrayerService,
        ),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Ecoute l'etat d'authentification et demarre le service temps reel
/// + programmation automatique des notifications quand l'utilisateur se connecte
void _startRealtimeServiceWhenReady(
  AuthService authService,
  RealtimePrayerService realtimePrayerService,
) {
  authService.authStateChanges.listen((user) async {
    if (user != null) {
      // Utilisateur connecte : demarrer le service et programmer les notifications
      await realtimePrayerService.start();
      await realtimePrayerService.scheduleTodayPrayers();
    }
  });
}
