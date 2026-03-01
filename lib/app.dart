import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'features/authentication/presentation/screens/auth_wrapper.dart';
import 'features/prayer_notification/presentation/screens/fullscreen_prayer_alert.dart';
import 'routes.dart';
import 'shared/themes/app_theme.dart';
import 'core/services/theme_service.dart';
import 'core/services/notification_service.dart';
import 'main.dart' show globalNotificationService, onNotificationActionReceived;

/// Cle de navigation globale pour acceder au navigateur depuis les handlers statiques
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> onNotificationDisplayed(ReceivedNotification receivedNotification) async {
  // Afficher l'alerte plein ecran pour les rappels quand l'app est au premier plan
  if (receivedNotification.channelKey != 'reminder_channel') return;

  final context = navigatorKey.currentContext;
  if (context == null) return;

  try {
    final notificationService = globalNotificationService;
    if (notificationService == null) return;

    final int notificationId = receivedNotification.id ?? 0;
    final String prayerName = receivedNotification.title
            ?.replaceAll('Rappel:', '')
            .replaceAll(RegExp(r'!+$'), '')
            .trim() ??
        'Priere';

    final reminderCount = await notificationService.getReminderCount(notificationId);

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => FullscreenPrayerAlert(
          prayerName: prayerName,
          scheduledTime: DateTime.now(),
          reminderCount: reminderCount,
          maxReminders: NotificationService.MAX_REMINDERS,
          onPrayerCompleted: () async {
            await notificationService.resetReminderCount(notificationId);
            await notificationService.cancelNotification(notificationId);
            Navigator.of(ctx).pop();
          },
          onRemindLater: () async {
            await notificationService.scheduleNextReminder(
                notificationId, 'Rappel: $prayerName');
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  } catch (e) {
    print('Erreur lors de l\'affichage de l\'alerte: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
  }

  Future<void> _setupNotificationListeners() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onNotificationActionReceived,
      onNotificationDisplayedMethod: onNotificationDisplayed,
      onNotificationCreatedMethod: _onNotificationCreated,
      onDismissActionReceivedMethod: _onDismissAction,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> _onDismissAction(ReceivedAction receivedAction) async {}

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'TaqwaTime',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: const AuthWrapper(),
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page non trouvee'),
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
