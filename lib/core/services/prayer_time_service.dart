import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';
import '../models/user_settings_model.dart' as app;
import '../services/location_service.dart';

class PrayerTimeService {
  final LocationService _locationService = LocationService();

  /// Charge la methode de calcul sauvegardee dans les settings utilisateur
  Future<CalculationMethod> _getSavedCalculationMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Chercher dans les settings locaux de l'utilisateur
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_settings_')) {
          final settingsJson = prefs.getString(key);
          if (settingsJson != null && settingsJson.contains('calculationMethod')) {
            final methodName = RegExp(r'"calculationMethod"\s*:\s*"(\w+)"')
                .firstMatch(settingsJson)
                ?.group(1);
            if (methodName != null) {
              return _toAdhanMethod(app.CalculationMethod.values.byName(methodName));
            }
          }
        }
      }
    } catch (_) {}
    return CalculationMethod.muslim_world_league;
  }

  /// Charge le madhab sauvegarde dans les settings utilisateur
  Future<Madhab> _getSavedMadhab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_settings_')) {
          final settingsJson = prefs.getString(key);
          if (settingsJson != null && settingsJson.contains('madhab')) {
            final madhabName = RegExp(r'"madhab"\s*:\s*"(\w+)"')
                .firstMatch(settingsJson)
                ?.group(1);
            if (madhabName != null) {
              return _toAdhanMadhab(app.Madhab.values.byName(madhabName));
            }
          }
        }
      }
    } catch (_) {}
    return Madhab.shafi;
  }

  /// Convertir la methode de calcul de l'app vers celle du package adhan
  CalculationMethod _toAdhanMethod(app.CalculationMethod method) {
    switch (method) {
      case app.CalculationMethod.mwl:
        return CalculationMethod.muslim_world_league;
      case app.CalculationMethod.isna:
        return CalculationMethod.north_america;
      case app.CalculationMethod.egypt:
        return CalculationMethod.egyptian;
      case app.CalculationMethod.karachi:
        return CalculationMethod.karachi;
      case app.CalculationMethod.tehran:
        return CalculationMethod.tehran;
      case app.CalculationMethod.jafari:
        return CalculationMethod.kuwait;
    }
  }

  /// Charge les offsets de priere sauvegardes dans les settings utilisateur
  Future<Map<String, int>> _getSavedPrayerOffsets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_settings_')) {
          final settingsJson = prefs.getString(key);
          if (settingsJson != null && settingsJson.contains('prayerOffsets')) {
            final match = RegExp(r'"prayerOffsets"\s*:\s*\{([^}]*)\}')
                .firstMatch(settingsJson);
            if (match != null) {
              final offsetsStr = match.group(1)!;
              final offsets = <String, int>{};
              final entries = RegExp(r'"(\w+)"\s*:\s*(-?\d+)');
              for (final m in entries.allMatches(offsetsStr)) {
                offsets[m.group(1)!] = int.parse(m.group(2)!);
              }
              return offsets;
            }
          }
        }
      }
    } catch (_) {}
    return {};
  }

  /// Applique les offsets aux horaires de priere
  Map<PrayerType, DateTime> _applyOffsets(
    Map<PrayerType, DateTime> times,
    Map<String, int> offsets,
  ) {
    if (offsets.isEmpty) return times;
    return times.map((type, time) {
      final offset = offsets[type.name] ?? 0;
      return MapEntry(type, time.add(Duration(minutes: offset)));
    });
  }

  /// Convertir le madhab de l'app vers celui du package adhan
  Madhab _toAdhanMadhab(app.Madhab madhab) {
    switch (madhab) {
      case app.Madhab.shafi:
        return Madhab.shafi;
      case app.Madhab.hanafi:
        return Madhab.hanafi;
    }
  }

  // Obtenir tous les horaires de priere pour une journee
  Future<PrayerTimes> getPrayerTimesForLocation({
    DateTime? date,
    CalculationParameters? parameters,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    // Obtenir les coordonnees de l'utilisateur (Abidjan par defaut)
    final (latitude, longitude) = await _locationService.getCoordinates();
    final coordinates = Coordinates(latitude, longitude);

    // Charger les parametres : argument > settings sauvegardes > defaut
    CalculationParameters params;
    if (parameters != null) {
      params = parameters;
    } else if (calculationMethod != null) {
      params = calculationMethod.getParameters();
    } else {
      final savedMethod = await _getSavedCalculationMethod();
      params = savedMethod.getParameters();
    }

    if (madhab != null) {
      params.madhab = madhab;
    } else {
      params.madhab = await _getSavedMadhab();
    }

    final dateToUse = date ?? DateTime.now();
    final dateComponents = DateComponents(dateToUse.year, dateToUse.month, dateToUse.day);

    return PrayerTimes(coordinates, dateComponents, params);
  }

  // Creer les modeles de priere pour une journee
  Future<List<PrayerModel>> createDailyPrayers({
    required String userId,
    DateTime? date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    final today = date ?? DateTime.now();
    final prayerTimes = await getPrayerTimesForLocation(
      date: today,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    final offsets = await _getSavedPrayerOffsets();
    final rawTimes = {
      PrayerType.fajr: prayerTimes.fajr,
      PrayerType.dhuhr: prayerTimes.dhuhr,
      PrayerType.asr: prayerTimes.asr,
      PrayerType.maghrib: prayerTimes.maghrib,
      PrayerType.isha: prayerTimes.isha,
    };
    final adjustedTimes = _applyOffsets(rawTimes, offsets);

    final List<PrayerModel> prayers = [];
    final now = DateTime.now();

    for (final type in PrayerType.values) {
      final time = adjustedTimes[type]!;
      prayers.add(PrayerModel(
        id: '${userId}_${today.year}${today.month}${today.day}_${type.name}',
        userId: userId,
        type: type,
        scheduledTime: time,
        status: now.isAfter(time) ? PrayerStatus.missed : PrayerStatus.notYet,
      ));
    }

    return prayers;
  }

  // Obtenir la prochaine priere
  Future<(PrayerType, DateTime)> getNextPrayer({
    DateTime? date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    final prayerTimes = await getPrayerTimesForLocation(
      date: date,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    final offsets = await _getSavedPrayerOffsets();
    final rawTimes = {
      PrayerType.fajr: prayerTimes.fajr,
      PrayerType.dhuhr: prayerTimes.dhuhr,
      PrayerType.asr: prayerTimes.asr,
      PrayerType.maghrib: prayerTimes.maghrib,
      PrayerType.isha: prayerTimes.isha,
    };
    final adjusted = _applyOffsets(rawTimes, offsets);

    final now = DateTime.now();

    for (final type in PrayerType.values) {
      if (now.isBefore(adjusted[type]!)) {
        return (type, adjusted[type]!);
      }
    }

    // Si toutes les prieres sont passees, calculer Fajr pour demain
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowPrayers = await getPrayerTimesForLocation(
      date: tomorrow,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );
    final tomorrowRaw = {
      PrayerType.fajr: tomorrowPrayers.fajr,
    };
    final tomorrowAdjusted = _applyOffsets(tomorrowRaw, offsets);

    return (PrayerType.fajr, tomorrowAdjusted[PrayerType.fajr]!);
  }

  // Obtenir tous les horaires de priere pour le jour
  Future<Map<PrayerType, DateTime>> getAllPrayerTimes({
    DateTime? date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    final prayerTimes = await getPrayerTimesForLocation(
      date: date,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    final offsets = await _getSavedPrayerOffsets();
    final rawTimes = {
      PrayerType.fajr: prayerTimes.fajr,
      PrayerType.dhuhr: prayerTimes.dhuhr,
      PrayerType.asr: prayerTimes.asr,
      PrayerType.maghrib: prayerTimes.maghrib,
      PrayerType.isha: prayerTimes.isha,
    };

    return _applyOffsets(rawTimes, offsets);
  }

  // Obtenir le nom de la priere
  String getPrayerName(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr: return 'Fajr';
      case PrayerType.dhuhr: return 'Dhuhr';
      case PrayerType.asr: return 'Asr';
      case PrayerType.maghrib: return 'Maghrib';
      case PrayerType.isha: return 'Isha';
    }
  }

  // Formater l'heure de la priere
  String formatPrayerTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  // Calculer le temps restant jusqu'a la prochaine priere
  Duration timeUntilNextPrayer(DateTime prayerTime) {
    final now = DateTime.now();
    return prayerTime.difference(now);
  }

  // Calculer la duree en format lisible
  String formatDuration(Duration duration) {
    if (duration.isNegative) {
      return "En retard";
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  // Programmer les notifications pour toutes les prieres du jour
  Future<void> schedulePrayerNotifications({
    required String userId,
    required Function(int id, String title, String body, DateTime time, Map<String, String> payload) scheduleNotification,
    DateTime? date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    final prayers = await createDailyPrayers(
      userId: userId,
      date: date,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    final now = DateTime.now();

    for (var prayer in prayers) {
      if (prayer.scheduledTime.isAfter(now)) {
        final title = 'Heure de la priere';
        final body = 'C\'est l\'heure de ${getPrayerName(prayer.type)} (${formatPrayerTime(prayer.scheduledTime)})';

        final notificationId = _generateNotificationId(prayer.id);

        await scheduleNotification(
          notificationId,
          title,
          body,
          prayer.scheduledTime,
          {'prayer_id': prayer.id, 'prayer_type': prayer.type.name},
        );
      }
    }
  }

  int _generateNotificationId(String prayerId) {
    int hash = 0;
    for (int i = 0; i < prayerId.length; i++) {
      hash = (hash * 31 + prayerId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (hash % 9999999) + 1;
  }
}
