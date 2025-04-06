import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';
import '../services/location_service.dart';

class PrayerTimeService {
  final LocationService _locationService = LocationService();

  // Obtenir tous les horaires de prière pour une journée
  Future<PrayerTimes> getPrayerTimesForLocation({
    DateTime? date,
    CalculationParameters? parameters,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    // Obtenir les coordonnées de l'utilisateur
    final (latitude, longitude) = await _locationService.getCoordinates();

    final coordinates = Coordinates(latitude, longitude);
    final params = parameters ??
        (calculationMethod?.getParameters() ??
            CalculationMethod.muslim_world_league.getParameters());

    // Définir le madhab si fourni
    if (madhab != null) {
      params.madhab = madhab;
    }

    final dateToUse = date ?? DateTime.now();
    final dateComponents = DateComponents(dateToUse.year, dateToUse.month, dateToUse.day);

    return PrayerTimes(coordinates, dateComponents, params);
  }

  // Créer les modèles de prière pour une journée
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

    final List<PrayerModel> prayers = [];
    final now = DateTime.now();

    // Fajr
    prayers.add(PrayerModel(
      id: '${userId}_${today.year}${today.month}${today.day}_fajr',
      userId: userId,
      type: PrayerType.fajr,
      scheduledTime: prayerTimes.fajr,
      status: now.isAfter(prayerTimes.fajr) ? PrayerStatus.missed : PrayerStatus.notYet,
    ));

    // Dhuhr
    prayers.add(PrayerModel(
      id: '${userId}_${today.year}${today.month}${today.day}_dhuhr',
      userId: userId,
      type: PrayerType.dhuhr,
      scheduledTime: prayerTimes.dhuhr,
      status: now.isAfter(prayerTimes.dhuhr) ? PrayerStatus.missed : PrayerStatus.notYet,
    ));

    // Asr
    prayers.add(PrayerModel(
      id: '${userId}_${today.year}${today.month}${today.day}_asr',
      userId: userId,
      type: PrayerType.asr,
      scheduledTime: prayerTimes.asr,
      status: now.isAfter(prayerTimes.asr) ? PrayerStatus.missed : PrayerStatus.notYet,
    ));

    // Maghrib
    prayers.add(PrayerModel(
      id: '${userId}_${today.year}${today.month}${today.day}_maghrib',
      userId: userId,
      type: PrayerType.maghrib,
      scheduledTime: prayerTimes.maghrib,
      status: now.isAfter(prayerTimes.maghrib) ? PrayerStatus.missed : PrayerStatus.notYet,
    ));

    // Isha
    prayers.add(PrayerModel(
      id: '${userId}_${today.year}${today.month}${today.day}_isha',
      userId: userId,
      type: PrayerType.isha,
      scheduledTime: prayerTimes.isha,
      status: now.isAfter(prayerTimes.isha) ? PrayerStatus.missed : PrayerStatus.notYet,
    ));

    return prayers;
  }

  // Obtenir la prochaine prière
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

    final now = DateTime.now();

    if (now.isBefore(prayerTimes.fajr)) {
      return (PrayerType.fajr, prayerTimes.fajr);
    }
    if (now.isBefore(prayerTimes.dhuhr)) {
      return (PrayerType.dhuhr, prayerTimes.dhuhr);
    }
    if (now.isBefore(prayerTimes.asr)) {
      return (PrayerType.asr, prayerTimes.asr);
    }
    if (now.isBefore(prayerTimes.maghrib)) {
      return (PrayerType.maghrib, prayerTimes.maghrib);
    }
    if (now.isBefore(prayerTimes.isha)) {
      return (PrayerType.isha, prayerTimes.isha);
    }

    // Si toutes les prières sont passées, calculer Fajr pour demain
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowPrayers = await getPrayerTimesForLocation(
      date: tomorrow,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    return (PrayerType.fajr, tomorrowPrayers.fajr);
  }

  // Obtenir tous les horaires de prière pour le jour
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

    return {
      PrayerType.fajr: prayerTimes.fajr,
      PrayerType.dhuhr: prayerTimes.dhuhr,
      PrayerType.asr: prayerTimes.asr,
      PrayerType.maghrib: prayerTimes.maghrib,
      PrayerType.isha: prayerTimes.isha,
    };
  }

  // Obtenir le nom de la prière en français
  String getPrayerName(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr: return 'Fajr';
      case PrayerType.dhuhr: return 'Dhuhr';
      case PrayerType.asr: return 'Asr';
      case PrayerType.maghrib: return 'Maghrib';
      case PrayerType.isha: return 'Isha';
    }
  }

  // Formater l'heure de la prière
  String formatPrayerTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  // Calculer le temps restant jusqu'à la prochaine prière
  Duration timeUntilNextPrayer(DateTime prayerTime) {
    final now = DateTime.now();
    return prayerTime.difference(now);
  }

  // Calculer la durée en format lisible
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

  // Programmer les notifications pour toutes les prières du jour
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
      // Ne programmer que les notifications pour les prières à venir
      if (prayer.scheduledTime.isAfter(now)) {
        final title = 'Heure de la prière';
        final body = 'C\'est l\'heure de ${getPrayerName(prayer.type)} (${formatPrayerTime(prayer.scheduledTime)})';

        // Générer un ID unique pour la notification
        final notificationId = int.parse(
            prayer.id.hashCode.toString().substring(0, 8).replaceAll('-', '1')
        );

        // Programmer la notification
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
}