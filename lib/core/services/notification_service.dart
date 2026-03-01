import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/themes/app_colors.dart';
import '../models/prayer_model.dart';
import '../models/user_settings_model.dart';
import '../repositories/settings_repository.dart';

class NotificationService {
  // Intervalles de rappel en minutes (escalade progressive)
  static const List<int> REMINDER_INTERVALS = [5, 3, 2, 1];

  // Intervalles de preparation avant la priere (en minutes)
  static const List<int> PREPARATION_INTERVALS = [30, 15, 5];

  // Nombre maximum de rappels
  static const int MAX_REMINDERS = 5;

  // Cles SharedPreferences
  static const String PREF_REMINDER_COUNT = 'reminder_count_';
  static const String PREF_LAST_INTENSITY = 'last_intensity_';

  // Repository pour recuperer les parametres utilisateur
  final SettingsRepository _settingsRepository;

  NotificationService(this._settingsRepository);

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'prayer_channel',
          channelName: 'Prayer Notifications',
          channelDescription: 'Notifications pour les horaires de priere',
          defaultColor: AppColors.primary,
          importance: NotificationImportance.High,
          ledColor: AppColors.primary,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          onlyAlertOnce: false,
        ),
        NotificationChannel(
          channelKey: 'reminder_channel',
          channelName: 'Prayer Reminders',
          channelDescription: 'Rappels insistants pour les prieres manquees',
          defaultColor: AppColors.alert,
          importance: NotificationImportance.Max,
          ledColor: AppColors.alert,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          playSound: true,
          channelShowBadge: true,
          onlyAlertOnce: false,
        ),
        NotificationChannel(
          channelKey: 'preparation_channel',
          channelName: 'Prayer Preparation',
          channelDescription: 'Notifications pour se preparer aux prieres',
          defaultColor: AppColors.secondary,
          importance: NotificationImportance.High,
          ledColor: AppColors.secondary,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          onlyAlertOnce: false,
        ),
      ],
    );

    // Demander les permissions et attendre le resultat
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // --- Methodes publiques ---

  Future<void> resetReminderCount(int id) async {
    await _resetReminderCount(id);
  }

  Future<void> scheduleNextReminder(int id, String title) async {
    await _scheduleNextReminder(id, title);
  }

  Future<int> getReminderCount(int id) async {
    return await _getReminderCount(id);
  }

  Future<void> stopAllReminders(int id) async {
    await _resetReminderCount(id);
    // Annuler toute notification de rappel programmee
    await AwesomeNotifications().cancel(_generateReminderId(id));
  }

  int generateNotificationId(String prayerId) {
    return _generateNotificationId(prayerId);
  }

  // --- Programmation de la sequence complete pour une priere ---

  Future<void> schedulePrayerNotificationSequence({
    required String prayerId,
    required PrayerType prayerType,
    required String prayerName,
    required DateTime scheduledTime,
    required DateTime? nextPrayerTime,
    required String nextPrayerName,
    required String userId,
  }) async {
    // Recuperer les parametres utilisateur
    final userSettings = await _settingsRepository.getUserSettings(userId);

    // Verifier si les notifications sont activees
    if (userSettings?.notificationsEnabled != true) {
      return;
    }

    // Sauvegarder l'ID utilisateur
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);

    // Nettoyer les notifications existantes pour cette priere
    final notificationId = _generateNotificationId(prayerId);
    await cancelNotification(notificationId);
    await _resetReminderCount(notificationId);

    final now = DateTime.now();
    final minutesAfterPrayer = now.difference(scheduledTime).inMinutes;

    // Plus d'une heure apres : ignorer
    if (minutesAfterPrayer > 60) {
      return;
    }

    // Priere recemment passee : envoyer un rappel urgent immediatement
    if (minutesAfterPrayer > 0) {
      await createReminderNotification(
        id: notificationId,
        title: 'Priere manquee : $prayerName',
        body: 'Vous avez manque la priere $prayerName il y a $minutesAfterPrayer minutes. Rattrapez-la maintenant !',
        intensityLevel: 2,
      );
      // Programmer un rappel de suivi dans 10 minutes (notification programmee, pas un Timer)
      await _scheduleReminderNotification(
        id: notificationId,
        title: 'Rappel urgent: $prayerName',
        body: 'Vous n\'avez pas encore confirme votre priere $prayerName !',
        delayMinutes: 10,
        intensityLevel: 3,
      );
      return;
    }

    // 1. Notifications de preparation (30, 15, 5 min avant)
    await _schedulePreparationNotifications(
      notificationId: notificationId,
      prayerName: prayerName,
      scheduledTime: scheduledTime,
    );

    // 2. Notification principale a l'heure de la priere
    await schedulePrayerNotification(
      id: notificationId,
      title: 'Heure de la priere',
      body: 'C\'est l\'heure de la priere $prayerName',
      scheduledTime: scheduledTime,
      userSettings: userSettings,
    );

    // 3. Rappel automatique programme (notification schedulee, survit a la fermeture de l'app)
    int reminderDelay = _isImportantPrayer(prayerType) ? 15 : 10;
    await _scheduleReminderNotification(
      id: notificationId,
      title: 'Rappel: $prayerName',
      body: 'Vous n\'avez pas encore confirme votre priere !',
      delayMinutes: reminderDelay,
      intensityLevel: 1,
      fromScheduledTime: scheduledTime,
    );

    // 4. Notification de transition a mi-chemin vers la prochaine priere
    if (nextPrayerTime != null) {
      final timeDifference = nextPrayerTime.difference(scheduledTime);
      final midPoint = scheduledTime.add(Duration(minutes: timeDifference.inMinutes ~/ 2));

      if (midPoint.isAfter(now) && midPoint.isAfter(scheduledTime.add(const Duration(minutes: 30)))) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: _generateTransitionNotificationId(notificationId),
            channelKey: 'prayer_channel',
            title: 'Rappel de priere',
            body: 'N\'oubliez pas de faire votre priere $prayerName avant $nextPrayerName (${_formatTime(nextPrayerTime)})',
            category: NotificationCategory.Reminder,
            wakeUpScreen: true,
            color: AppColors.secondary,
          ),
          schedule: NotificationCalendar.fromDate(
            date: midPoint,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  // --- Notifications de preparation ---

  Future<void> _schedulePreparationNotifications({
    required int notificationId,
    required String prayerName,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();

    for (var minutes in PREPARATION_INTERVALS) {
      final preparationTime = scheduledTime.subtract(Duration(minutes: minutes));

      if (preparationTime.isAfter(now)) {
        String body;
        if (minutes >= 30) {
          body = 'Preparez-vous pour la priere $prayerName dans $minutes minutes';
        } else if (minutes >= 15) {
          body = 'La priere $prayerName approche, $minutes minutes restantes';
        } else {
          body = 'Attention! Priere $prayerName dans $minutes minutes';
        }

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: _generatePreparationNotificationId(notificationId, minutes),
            channelKey: 'preparation_channel',
            title: 'Preparation: $prayerName',
            body: body,
            category: NotificationCategory.Reminder,
            wakeUpScreen: minutes < 10,
            color: AppColors.secondary,
          ),
          schedule: NotificationCalendar.fromDate(
            date: preparationTime,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  // --- Notification principale de priere ---

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required UserSettingsModel? userSettings,
    int delayMinutes = 0,
  }) async {
    await _resetReminderCount(id);

    final vibrationEnabled = userSettings?.vibrationEnabled ?? true;
    final soundEnabled = userSettings?.notificationsEnabled ?? true;
    final intensity = userSettings?.notificationIntensity ?? NotificationIntensity.medium;

    bool wakeUpScreen = intensity == NotificationIntensity.high;
    bool criticalAlert = intensity == NotificationIntensity.high;
    bool locked = intensity != NotificationIntensity.low;

    final notifDate = scheduledTime.add(Duration(minutes: delayMinutes));

    // Ne programmer que si dans le futur
    if (notifDate.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'prayer_channel',
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        wakeUpScreen: wakeUpScreen,
        autoDismissible: false,
        criticalAlert: criticalAlert,
        color: AppColors.primary,
        notificationLayout: NotificationLayout.Default,
        locked: locked,
        displayOnForeground: true,
        displayOnBackground: true,
        payload: {
          'vibration': vibrationEnabled.toString(),
          'sound': soundEnabled.toString(),
          'intensity': intensity.name,
        },
      ),
      schedule: NotificationCalendar.fromDate(
        date: notifDate,
        allowWhileIdle: true,
        preciseAlarm: true,
        repeats: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_DONE',
          label: 'Priere accomplie',
          color: AppColors.primary,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: 'Rappeler dans 5 min',
          color: AppColors.secondary,
          autoDismissible: false,
        ),
      ],
    );
  }

  // --- Rappels programmes (notifications schedulees, pas de Timer) ---

  /// Programme une notification de rappel dans le futur
  /// Utilise AwesomeNotifications schedule au lieu de Timer pour survivre
  /// a la fermeture de l'app
  Future<void> _scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required int delayMinutes,
    required int intensityLevel,
    DateTime? fromScheduledTime,
  }) async {
    final DateTime scheduleDate;
    if (fromScheduledTime != null) {
      scheduleDate = fromScheduledTime.add(Duration(minutes: delayMinutes));
    } else {
      scheduleDate = DateTime.now().add(Duration(minutes: delayMinutes));
    }

    // Ne programmer que si dans le futur
    if (scheduleDate.isBefore(DateTime.now())) return;

    String alertEmojis = '';
    for (int i = 0; i < intensityLevel; i++) {
      alertEmojis += '!';
    }

    final reminderId = _generateReminderId(id);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminderId,
        channelKey: 'reminder_channel',
        title: '$title $alertEmojis',
        body: body,
        locked: true,
        displayOnForeground: true,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: false,
        criticalAlert: true,
        displayOnBackground: true,
        color: AppColors.alert,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduleDate,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_DONE',
          label: 'Priere accomplie',
          color: AppColors.primary,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: 'Rappeler bientot',
          color: AppColors.secondary,
          autoDismissible: false,
        ),
      ],
    );
  }

  /// Quand l'utilisateur clique "Rappeler plus tard"
  /// Programme UN SEUL rappel (pas de double-queuing)
  Future<void> _scheduleNextReminder(int id, String title) async {
    await _incrementReminderCount(id);
    int reminderCount = await _getReminderCount(id);

    if (reminderCount > MAX_REMINDERS) {
      // Max atteint, ne plus rappeler
      return;
    }

    // Determiner l'intervalle
    int intervalIndex = (reminderCount - 1) % REMINDER_INTERVALS.length;
    int delayMinutes = REMINDER_INTERVALS[intervalIndex];

    // Annuler tout rappel existant pour eviter le double-queuing
    await AwesomeNotifications().cancel(_generateReminderId(id));

    await _scheduleReminderNotification(
      id: id,
      title: title,
      body: 'N\'oubliez pas votre priere ! (Rappel $reminderCount/$MAX_REMINDERS)',
      delayMinutes: delayMinutes,
      intensityLevel: reminderCount,
    );
  }

  // --- Notification de rappel immediate ---

  Future<void> createReminderNotification({
    required int id,
    required String title,
    required String body,
    int intensityLevel = 1,
    int delayMinutes = 0,
  }) async {
    await _saveReminderIntensity(id, intensityLevel);

    String alertEmojis = '';
    for (int i = 0; i < intensityLevel; i++) {
      alertEmojis += '!';
    }

    final reminderId = delayMinutes > 0 ? _generateReminderId(id) : id;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminderId,
        channelKey: 'reminder_channel',
        title: '$title $alertEmojis',
        body: body,
        locked: true,
        displayOnForeground: true,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: false,
        criticalAlert: true,
        displayOnBackground: true,
        color: AppColors.alert,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: delayMinutes > 0
          ? NotificationCalendar.fromDate(
              date: DateTime.now().add(Duration(minutes: delayMinutes)),
              allowWhileIdle: true,
              preciseAlarm: true,
            )
          : null,
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_DONE',
          label: 'Priere accomplie',
          color: AppColors.primary,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: 'Rappeler bientot',
          color: AppColors.secondary,
          autoDismissible: false,
        ),
      ],
    );
  }

  // --- Generation d'ID deterministe ---

  /// Genere un ID stable et deterministe a partir du prayerId
  /// Utilise un hash simple base sur les caracteres au lieu de hashCode
  /// qui peut varier entre sessions Dart
  int _generateNotificationId(String prayerId) {
    int hash = 0;
    for (int i = 0; i < prayerId.length; i++) {
      hash = (hash * 31 + prayerId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    // Garder dans une plage raisonnable (1-9999999)
    return (hash % 9999999) + 1;
  }

  int _generatePreparationNotificationId(int baseId, int minutes) {
    return 10000000 + (baseId % 1000000) + (minutes * 1000);
  }

  int _generateTransitionNotificationId(int baseId) {
    return 20000000 + (baseId % 1000000);
  }

  int _generateReminderId(int baseId) {
    return 30000000 + (baseId % 1000000);
  }

  // --- Helpers ---

  bool _isImportantPrayer(PrayerType prayerType) {
    switch (prayerType) {
      case PrayerType.fajr:
      case PrayerType.maghrib:
      case PrayerType.isha:
        return true;
      case PrayerType.dhuhr:
      case PrayerType.asr:
        return false;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // --- Persistence des compteurs ---

  Future<void> _incrementReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('$PREF_REMINDER_COUNT$id') ?? 0;
    await prefs.setInt('$PREF_REMINDER_COUNT$id', currentCount + 1);
  }

  Future<int> _getReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$PREF_REMINDER_COUNT$id') ?? 0;
  }

  Future<void> _resetReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$PREF_REMINDER_COUNT$id', 0);
  }

  Future<void> _saveReminderIntensity(int id, int intensity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$PREF_LAST_INTENSITY$id', intensity);
  }

  // --- Annulation ---

  Future<void> cancelNotification(int id) async {
    // Annuler la notification principale
    await AwesomeNotifications().cancel(id);

    // Annuler le rappel programme
    await AwesomeNotifications().cancel(_generateReminderId(id));

    // Annuler les notifications de preparation
    for (var minutes in PREPARATION_INTERVALS) {
      await AwesomeNotifications().cancel(_generatePreparationNotificationId(id, minutes));
    }

    // Annuler la notification de transition
    await AwesomeNotifications().cancel(_generateTransitionNotificationId(id));
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
