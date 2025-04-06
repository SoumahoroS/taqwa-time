import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/themes/app_colors.dart';
import '../models/prayer_model.dart';

class NotificationService {
  // Constantes pour les intervalles de rappel (en minutes)
  static const List<int> REMINDER_INTERVALS = [5, 3, 2, 1];

  // Intervalles pour les notifications de préparation (en minutes avant la prière)
  static const List<int> PREPARATION_INTERVALS = [30, 15, 5];

  // Nombre maximum de rappels
  static const int MAX_REMINDERS = 5;

  // Préférences pour stocker l'état des rappels
  static const String PREF_REMINDER_COUNT = 'reminder_count_';
  static const String PREF_LAST_INTENSITY = 'last_intensity_';

  // Timers pour gérer les rappels automatiques
  final Map<int, Timer> _reminderTimers = {};
  final Map<int, List<Timer>> _preparationTimers = {};

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // Utiliser l'icône de l'application par défaut
      [
        NotificationChannel(
          channelKey: 'prayer_channel',
          channelName: 'Prayer Notifications',
          channelDescription: 'Notifications pour les horaires de prière',
          defaultColor: AppColors.primary,
          importance: NotificationImportance.High,
          ledColor: AppColors.primary,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'reminder_channel',
          channelName: 'Prayer Reminders',
          channelDescription: 'Rappels insistants pour les prières manquées',
          defaultColor: AppColors.alert,
          importance: NotificationImportance.Max,
          ledColor: AppColors.alert,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
        NotificationChannel(
          channelKey: 'preparation_channel',
          channelName: 'Prayer Preparation',
          channelDescription: 'Notifications pour se préparer aux prières',
          defaultColor: AppColors.secondary,
          importance: NotificationImportance.High,
          ledColor: AppColors.secondary,
          enableVibration: true,
        ),
      ],
    );

    // Demander les permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Méthodes publiques pour être utilisées par le gestionnaire global d'actions

  // Réinitialiser le compteur de rappels (utilisé quand une prière est marquée comme accomplie)
  Future<void> resetReminderCount(int id) async {
    _stopReminderTimer(id);
    await _resetReminderCount(id);
  }

  // Programmer le prochain rappel avec une intensité accrue
  Future<void> scheduleNextReminder(int id, String title) async {
    _stopReminderTimer(id);
    await _scheduleNextReminder(id, title);
  }

  // Programmer toutes les notifications pour une prière
  Future<void> schedulePrayerNotificationSequence({
    required String prayerId,
    required PrayerType prayerType,
    required String prayerName,
    required DateTime scheduledTime,
    required DateTime? nextPrayerTime,
    required String nextPrayerName,
  }) async {
    // Nettoyer les notifications existantes pour cette prière
    final notificationId = _generateNotificationId(prayerId);
    await cancelNotification(notificationId);

    // Réinitialiser les compteurs
    await _resetReminderCount(notificationId);

    final now = DateTime.now();

    // Si la prière est déjà passée de plus d'une heure, ne pas programmer de notification
    if (scheduledTime.difference(now).inMinutes < -60) {
      return;
    }

    // 1. Phase de préparation: notifications avant l'heure de prière
    await _schedulePreparationNotifications(
        notificationId: notificationId,
        prayerName: prayerName,
        scheduledTime: scheduledTime
    );

    // 2. Notification principale à l'heure de la prière
    await schedulePrayerNotification(
      id: notificationId,
      title: 'Heure de la prière',
      body: 'C\'est l\'heure de la prière $prayerName',
      scheduledTime: scheduledTime,
      vibration: true,
    );

    // 3. Programmer les rappels automatiques si la prière n'est pas confirmée
    _scheduleAutoReminder(notificationId, 'Rappel: $prayerName', 10);

    // 4. Si la prochaine prière est prévue, ajouter une notification de transition
    if (nextPrayerTime != null) {
      // Calculer un point intermédiaire (à mi-chemin entre les deux prières)
      final midPoint = scheduledTime.add(Duration(
          minutes: scheduledTime.difference(nextPrayerTime).inMinutes ~/ 2
      ));

      // S'assurer que le point intermédiaire est dans le futur
      if (midPoint.isAfter(now)) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId + 1000, // ID différent pour éviter les conflits
            channelKey: 'prayer_channel',
            title: 'Rappel de prière',
            body: 'N\'oubliez pas de faire votre prière $prayerName avant $nextPrayerName (${_formatTime(nextPrayerTime)})',
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

  // Programmer les notifications de préparation
  Future<void> _schedulePreparationNotifications({
    required int notificationId,
    required String prayerName,
    required DateTime scheduledTime
  }) async {
    final now = DateTime.now();

    // Nettoyer les timers de préparation existants
    if (_preparationTimers.containsKey(notificationId)) {
      for (var timer in _preparationTimers[notificationId]!) {
        timer.cancel();
      }
      _preparationTimers.remove(notificationId);
    }

    _preparationTimers[notificationId] = [];

    // Créer des notifications pour chaque intervalle de préparation
    for (var minutes in PREPARATION_INTERVALS) {
      final preparationTime = scheduledTime.subtract(Duration(minutes: minutes));

      // Ne programmer que si le temps de préparation est dans le futur
      if (preparationTime.isAfter(now)) {
        // Préparer le texte en fonction du temps restant
        String body;
        if (minutes >= 30) {
          body = 'Préparez-vous pour la prière $prayerName dans $minutes minutes';
        } else if (minutes >= 15) {
          body = 'La prière $prayerName approche, $minutes minutes restantes';
        } else {
          body = 'Attention! Prière $prayerName dans $minutes minutes';
        }

        // Créer la notification de préparation
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId + minutes, // ID unique basé sur l'intervalle
            channelKey: 'preparation_channel',
            title: 'Préparation: $prayerName',
            body: body,
            category: NotificationCategory.Reminder,
            wakeUpScreen: minutes < 10, // Réveiller l'écran uniquement pour les rappels proches
            color: AppColors.secondary,
          ),
          schedule: NotificationCalendar.fromDate(
            date: preparationTime,
            allowWhileIdle: true,
          ),
        );

        // Ajouter un timer pour le cas où l'application est ouverte
        final timerDuration = preparationTime.difference(now);
        if (timerDuration.inSeconds > 0) {
          final timer = Timer(timerDuration, () {
            // Si l'application est en premier plan, on pourrait afficher un rappel ici
            print('Préparation: $prayerName dans $minutes minutes');
          });

          _preparationTimers[notificationId]!.add(timer);
        }
      }
    }
  }

  // Créer une notification de prière
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool vibration,
    String? soundSource,
    int delayMinutes = 0,
  }) async {
    // Réinitialiser le compteur de rappels pour cette notification
    await _resetReminderCount(id);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'prayer_channel',
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: false,  // Déjà configuré comme false, ce qui est correct
        criticalAlert: true,
        color: AppColors.primary,
        notificationLayout: NotificationLayout.Default,
        locked: true,  // Ajouter cette ligne pour verrouiller la notification
        displayOnForeground: true,  // Assurer l'affichage même si l'app est au premier plan
        displayOnBackground: true,  // Assurer l'affichage même si l'app est en arrière-plan
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime.add(Duration(minutes: delayMinutes)),
        allowWhileIdle: true,
        preciseAlarm: true,
        repeats: false,  // Ne pas répéter automatiquement
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_DONE',
          label: 'Prière accomplie',
          color: AppColors.primary,
          autoDismissible: false,  // Assurer que le bouton n'auto-supprime pas
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: 'Rappeler dans 5 min',
          color: AppColors.secondary,
          autoDismissible: false,  // Assurer que le bouton n'auto-supprime pas
        ),
      ],
    );
  }

  // Fonction pour programmer un rappel automatique si l'utilisateur ignore la notification
  void _scheduleAutoReminder(int id, String title, int delayMinutes) {
    _stopReminderTimer(id); // Arrêter tout timer existant

    _reminderTimers[id] = Timer(Duration(minutes: delayMinutes), () async {
      // Vérifier si la notification a été traitée
      bool notificationExists = await _checkIfNotificationExists(id);

      if (notificationExists) {
        // L'utilisateur a ignoré la notification, envoyer un rappel insistant
        await _incrementReminderCount(id);
        int reminderCount = await _getReminderCount(id);

        if (reminderCount <= MAX_REMINDERS) {
          await createReminderNotification(
            id: id,
            title: title,
            body: 'Vous n\'avez pas encore confirmé votre prière !',
            intensityLevel: reminderCount,
          );

          // Programmer le prochain rappel avec un délai plus court
          int nextInterval = REMINDER_INTERVALS[
          reminderCount < REMINDER_INTERVALS.length
              ? reminderCount
              : REMINDER_INTERVALS.length - 1
          ];
          _scheduleAutoReminder(id, title, nextInterval);
        }
      }
    });
  }

  // Programmer le prochain rappel avec une intensité accrue
  Future<void> _scheduleNextReminder(int id, String title) async {
    await _incrementReminderCount(id);
    int reminderCount = await _getReminderCount(id);

    if (reminderCount <= MAX_REMINDERS) {
      // Déterminer l'intervalle pour ce rappel
      int intervalIndex = (reminderCount - 1) % REMINDER_INTERVALS.length;
      int delayMinutes = REMINDER_INTERVALS[intervalIndex];

      await createReminderNotification(
        id: id,
        title: title,
        body: 'N\'oubliez pas votre prière ! (Rappel ${reminderCount}/${MAX_REMINDERS})',
        intensityLevel: reminderCount,
        delayMinutes: delayMinutes,
      );

      // Programmer un rappel automatique après ce délai
      _scheduleAutoReminder(id, title, delayMinutes + 5);
    }
  }

  // Créer une notification de rappel insistant pour une prière manquée
  Future<void> createReminderNotification({
    required int id,
    required String title,
    required String body,
    int intensityLevel = 1,
    int delayMinutes = 0,
  }) async {
    // Enregistrer l'intensité actuelle
    await _saveReminderIntensity(id, intensityLevel);

    // Création du titre avec des emojis d'alerte dont le nombre dépend de l'intensité
    String alertEmojis = '';
    for (int i = 0; i < intensityLevel; i++) {
      alertEmojis += '⚠️';
    }

    // Augmenter la taille du texte et ajouter des points d'exclamation selon l'intensité
    String emphasisBody = body;
    for (int i = 0; i < intensityLevel; i++) {
      emphasisBody += '!';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminder_channel',
        title: '$title $alertEmojis',
        body: emphasisBody,
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
          label: 'Prière accomplie',
          color: AppColors.primary,
          autoDismissible: false,

        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: 'Rappeler bientôt',
          color: AppColors.secondary,
          autoDismissible: false,

        ),
      ],
    );
  }

  // Vérifier si une notification existe encore (non traitée par l'utilisateur)
  Future<bool> _checkIfNotificationExists(int id) async {
    var activeNotifications = await AwesomeNotifications().listScheduledNotifications();
    for (var notification in activeNotifications) {
      if (notification.content?.id == id) {
        return true;
      }
    }

    // Vérifier le compteur global de notifications
    int badgeCount = await AwesomeNotifications().getGlobalBadgeCounter();
    return badgeCount > 0; // Approximation simple
  }

  // Stopper le timer de rappel pour une notification
  void _stopReminderTimer(int id) {
    if (_reminderTimers.containsKey(id)) {
      _reminderTimers[id]?.cancel();
      _reminderTimers.remove(id);
    }
  }

  // Incrémenter le compteur de rappels
  Future<void> _incrementReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('$PREF_REMINDER_COUNT$id') ?? 0;
    await prefs.setInt('$PREF_REMINDER_COUNT$id', currentCount + 1);
  }

  // Obtenir le compteur de rappels actuel
  Future<int> _getReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$PREF_REMINDER_COUNT$id') ?? 0;
  }

  // Réinitialiser le compteur de rappels
  Future<void> _resetReminderCount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$PREF_REMINDER_COUNT$id', 0);
  }

  // Sauvegarder l'intensité actuelle du rappel
  Future<void> _saveReminderIntensity(int id, int intensity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$PREF_LAST_INTENSITY$id', intensity);
  }

  // Générer un ID de notification à partir d'un ID de prière
  int _generateNotificationId(String prayerId) {
    return int.parse(
        prayerId.hashCode.toString().substring(0, 8).replaceAll('-', '1')
    );
  }

  // Formater l'heure pour l'affichage
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Annuler une notification
  Future<void> cancelNotification(int id) async {
    _stopReminderTimer(id);

    // Annuler également les notifications de préparation associées
    if (_preparationTimers.containsKey(id)) {
      for (var timer in _preparationTimers[id]!) {
        timer.cancel();
      }
      _preparationTimers.remove(id);
    }

    // Annuler la notification principale
    await AwesomeNotifications().cancel(id);

    // Annuler les notifications de préparation
    for (var minutes in PREPARATION_INTERVALS) {
      await AwesomeNotifications().cancel(id + minutes);
    }

    // Annuler la notification de transition
    await AwesomeNotifications().cancel(id + 1000);
  }

  // Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    _reminderTimers.forEach((id, timer) => timer.cancel());
    _reminderTimers.clear();

    _preparationTimers.forEach((id, timers) {
      for (var timer in timers) {
        timer.cancel();
      }
    });
    _preparationTimers.clear();

    await AwesomeNotifications().cancelAll();
  }
}