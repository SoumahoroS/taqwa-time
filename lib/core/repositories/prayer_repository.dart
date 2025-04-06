// lib/core/repositories/prayer_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_model.dart';

class PrayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Référence à la collection des prières
  CollectionReference get _prayersCollection =>
      _firestore.collection('prayers');

  // Référence à la collection des utilisateurs
  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Obtenir les prières d'un utilisateur pour une date spécifique
  Stream<List<PrayerModel>> getUserPrayers(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _prayersCollection
        .where('userId', isEqualTo: userId)
        .where(
        'scheduledTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('scheduledTime', isLessThan: endOfDay.toIso8601String())
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            PrayerModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Enregistrer une nouvelle prière
  Future<void> savePrayer(PrayerModel prayer) async {
    await _prayersCollection.doc(prayer.id).set(prayer.toJson());
  }

  // Enregistrer plusieurs prières à la fois
  Future<void> savePrayers(List<PrayerModel> prayers) async {
    final batch = _firestore.batch();

    for (var prayer in prayers) {
      var docRef = _prayersCollection.doc(prayer.id);
      batch.set(docRef, prayer.toJson());
    }

    await batch.commit();
  }

  // Mettre à jour le statut d'une prière
  Future<void> updatePrayerStatus(String prayerId,
      PrayerStatus status,
      DateTime? completedTime) async {
    await _prayersCollection.doc(prayerId).update({
      'status': status.name,
      'completedTime': completedTime?.toIso8601String(),
    });
  }

  // Obtenir les statistiques de prière d'un utilisateur
  Future<Map<String, dynamic>> getUserPrayerStats(String userId,
      int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _prayersCollection
        .where('userId', isEqualTo: userId)
        .where(
        'scheduledTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('scheduledTime', isLessThan: endDate.toIso8601String())
        .get();

    final prayers = snapshot.docs
        .map((doc) => PrayerModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    int onTime = 0;
    int late = 0;
    int missed = 0;
    int notYet = 0;
    Map<PrayerType, int> prayerTypeStats = {
      PrayerType.fajr: 0,
      PrayerType.dhuhr: 0,
      PrayerType.asr: 0,
      PrayerType.maghrib: 0,
      PrayerType.isha: 0,
    };
    Map<int, int> dailyCompletedCount = {
    }; // Jour → nombre de prières accomplies

    // Grouper les prières par jour pour analyse
    Map<String, List<PrayerModel>> prayersByDay = {};

    for (var prayer in prayers) {
      final date = prayer.scheduledTime;
      final dayKey = '${date.year}-${date.month}-${date.day}';

      if (!prayersByDay.containsKey(dayKey)) {
        prayersByDay[dayKey] = [];
      }
      prayersByDay[dayKey]!.add(prayer);

      // Compter par statut
      switch (prayer.status) {
        case PrayerStatus.onTime:
          onTime++;
          prayerTypeStats[prayer.type] =
              (prayerTypeStats[prayer.type] ?? 0) + 1;
          break;
        case PrayerStatus.late:
          late++;
          break;
        case PrayerStatus.missed:
          missed++;
          break;
        case PrayerStatus.notYet:
          notYet++;
          break;
      }

      // Ajouter au compteur journalier
      final daysSinceStart = date
          .difference(startDate)
          .inDays;
      if (prayer.status == PrayerStatus.onTime ||
          prayer.status == PrayerStatus.late) {
        dailyCompletedCount[daysSinceStart] =
            (dailyCompletedCount[daysSinceStart] ?? 0) + 1;
      }
    }

    // Analyser les tendances
    List<double> dailyPercentages = [];
    for (int i = 0; i < days; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final dayKey = '${dayDate.year}-${dayDate.month}-${dayDate.day}';
      final dayPrayers = prayersByDay[dayKey] ?? [];

      if (dayPrayers.isNotEmpty) {
        final completed = dayPrayers.where((p) =>
        p.status == PrayerStatus.onTime || p.status == PrayerStatus.late)
            .length;
        dailyPercentages.add((completed / dayPrayers.length) * 100);
      } else {
        dailyPercentages.add(0);
      }
    }

    // Calculer la tendance (en hausse, en baisse ou stable)
    String trend = 'stable';
    if (dailyPercentages.length > 3) {
      // Comparer la moyenne des 2 premiers jours avec celle des 2 derniers
      double firstAvg = (dailyPercentages.take(2).reduce((a, b) => a + b)) / 2;
      double lastAvg = (dailyPercentages.skip(dailyPercentages.length - 2)
          .take(2).reduce((a, b) => a + b)) / 2;

      if (lastAvg - firstAvg > 10) {
        trend = 'up';
      } else if (firstAvg - lastAvg > 10) {
        trend = 'down';
      }
    }

    // Calculer le streak actuel
    int currentStreak = 0;

    // Parcourir les jours en ordre décroissant
    for (int i = 0; i < days; i++) {
      final day = endDate.subtract(Duration(days: i));
      final dayKey = '${day.year}-${day.month}-${day.day}';
      final dayPrayers = prayersByDay[dayKey] ?? [];

      final allCompleted = dayPrayers.length == 5 &&
          dayPrayers.every((p) =>
          p.status == PrayerStatus.onTime || p.status == PrayerStatus.late);

      if (allCompleted) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Trouver le meilleur score de prières effectuées dans une journée
    int bestDayCount = 0;
    String bestDay = '';

    for (final entry in prayersByDay.entries) {
      final dayPrayers = entry.value;
      final completed = dayPrayers.where((p) =>
      p.status == PrayerStatus.onTime || p.status == PrayerStatus.late).length;

      if (completed > bestDayCount) {
        bestDayCount = completed;
        bestDay = entry.key;
      }
    }

    // Calculer la moyenne de ponctualité (pourcentage de prières effectuées à l'heure)
    double punctualityRate = 0;
    if (onTime + late > 0) {
      punctualityRate = (onTime / (onTime + late)) * 100;
    }

    return {
      'total': prayers.length,
      'onTime': onTime,
      'late': late,
      'missed': missed,
      'notYet': notYet,
      'byType': prayerTypeStats,
      'currentStreak': currentStreak,
      'bestStreak': await _getBestStreak(userId),
      // Récupérer le meilleur streak historique
      'bestDay': bestDay,
      'bestDayCount': bestDayCount,
      'trend': trend,
      'dailyPercentages': dailyPercentages,
      'punctualityRate': punctualityRate,
    };
  }

  // Obtenir le meilleur streak historique de l'utilisateur
  Future<int> _getBestStreak(String userId) async {
    try {
      // Vérifier d'abord s'il existe dans les données utilisateur
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('stats') &&
            userData['stats'] is Map &&
            (userData['stats'] as Map).containsKey('bestStreak')) {
          return userData['stats']['bestStreak'];
        }
      }

      // Si non trouvé, renvoyer 0 par défaut
      return 0;
    } catch (e) {
      print('Erreur lors de la récupération du meilleur streak: $e');
      return 0;
    }
  }

  // Mettre à jour le meilleur streak d'un utilisateur
  Future<void> updateBestStreak(String userId, int currentStreak) async {
    try {
      // Récupérer le meilleur streak actuel
      int bestStreak = await _getBestStreak(userId);

      // Si le streak actuel est meilleur, mettre à jour
      if (currentStreak > bestStreak) {
        await _usersCollection.doc(userId).set({
          'stats': {
            'bestStreak': currentStreak,
            'lastUpdated': DateTime.now().toIso8601String(),
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du meilleur streak: $e');
    }
  }
}