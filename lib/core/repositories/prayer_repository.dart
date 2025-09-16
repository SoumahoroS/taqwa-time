// lib/core/repositories/prayer_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_model.dart';
import '../services/cache_service.dart';

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
    
    // Invalider le cache des prières et statistiques de l'utilisateur
    await _invalidatePrayerCache(prayer.userId, prayer.scheduledTime);
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

  // Obtenir une prière spécifique par son ID
  Future<PrayerModel?> getPrayerById(String prayerId) async {
    try {
      DocumentSnapshot doc = await _prayersCollection.doc(prayerId).get();
      
      if (doc.exists) {
        return PrayerModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération de la prière: $e");
      return null;
    }
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

  // Obtenir les statistiques de prière d'un utilisateur avec cache
  Future<Map<String, dynamic>> getUserPrayerStats(String userId,
      int days) async {
    try {
      // Vérifier d'abord le cache
      final cachedStats = await CacheService.instance.getUserStats(userId);
      if (cachedStats != null) {
        return cachedStats;
      }

      // Si pas en cache, calculer depuis Firestore
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

    // Analyser les tendances avec logique améliorée
    List<double> dailyPercentages = [];
    List<bool> hasDataFlags = [];
    
    for (int i = 0; i < days; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final dayKey = '${dayDate.year}-${dayDate.month}-${dayDate.day}';
      final dayPrayers = prayersByDay[dayKey] ?? [];

      if (dayPrayers.isNotEmpty) {
        final completed = dayPrayers.where((p) =>
        p.status == PrayerStatus.onTime || p.status == PrayerStatus.late)
            .length;
        final expectedPrayers = _getExpectedPrayersForDate(dayDate);
        final percentage = expectedPrayers > 0 ? (completed / expectedPrayers) * 100.0 : 0.0;
        
        dailyPercentages.add(percentage);
        hasDataFlags.add(true);
      } else {
        // Pour les jours sans données, ne pas inclure dans le calcul de tendance
        dailyPercentages.add(0.0);
        hasDataFlags.add(false);
      }
    }

    // Calculer la tendance avec régression linéaire simple
    String trend = _calculateTrend(dailyPercentages, hasDataFlags);

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

      final stats = {
        'total': prayers.length,
        'onTime': onTime,
        'late': late,
        'missed': missed,
        'notYet': notYet,
        'byType': prayerTypeStats.map((key, value) => MapEntry(key.name, value)),
        'currentStreak': currentStreak,
        'bestStreak': await _getBestStreak(userId),
        'bestDay': bestDay,
        'bestDayCount': bestDayCount,
        'trend': trend,
        'dailyPercentages': dailyPercentages,
        'punctualityRate': punctualityRate,
      };

      // Mettre en cache les statistiques
      await CacheService.instance.putUserStats(userId, stats);
      
      return stats;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
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

  // Obtenir l'historique quotidien des prières pour les graphiques
  Future<List<Map<String, dynamic>>> getDailyPrayerHistory(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _prayersCollection
        .where('userId', isEqualTo: userId)
        .where('scheduledTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('scheduledTime', isLessThan: endDate.toIso8601String())
        .get();

    final prayers = snapshot.docs
        .map((doc) => PrayerModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Grouper les prières par jour
    Map<String, List<PrayerModel>> prayersByDay = {};
    
    for (var prayer in prayers) {
      final date = prayer.scheduledTime;
      final dayKey = '${date.year}-${date.month}-${date.day}';
      
      if (!prayersByDay.containsKey(dayKey)) {
        prayersByDay[dayKey] = [];
      }
      prayersByDay[dayKey]!.add(prayer);
    }

    // Créer l'historique quotidien avec logique améliorée
    List<Map<String, dynamic>> dailyHistory = [];
    
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayKey = '${date.year}-${date.month}-${date.day}';
      final dayPrayers = prayersByDay[dayKey] ?? [];
      
      // Calculer les statistiques réelles
      final onTime = dayPrayers.where((p) => p.status == PrayerStatus.onTime).length;
      final late = dayPrayers.where((p) => p.status == PrayerStatus.late).length;
      final missed = dayPrayers.where((p) => p.status == PrayerStatus.missed).length;
      final notYet = dayPrayers.where((p) => p.status == PrayerStatus.notYet).length;
      
      // Logique améliorée pour le total:
      // - Si des prières existent pour ce jour, utiliser le nombre réel
      // - Si aucune prière n'existe, calculer selon la logique métier
      int total;
      if (dayPrayers.isNotEmpty) {
        total = dayPrayers.length;
      } else {
        // Pour les jours sans données, ne pas assumer 5 prières
        // Utiliser 0 pour indiquer qu'il n'y a pas de données
        total = _getExpectedPrayersForDate(date);
      }
      
      final completed = onTime + late;
      
      // Validation des données
      final validCompleted = completed > total ? total : completed;
      final validMissed = missed > total ? total - validCompleted : missed;
      
      // Nom du jour en français
      final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final dayName = dayNames[date.weekday - 1];
      
      // Calculer le pourcentage de réussite
      final successRate = total > 0 ? (validCompleted / total * 100).round() : 0;
      
      
      dailyHistory.add({
        'date': date.toIso8601String(),
        'day': dayName,
        'total': total,
        'onTime': onTime,
        'late': late,
        'missed': validMissed,
        'notYet': notYet,
        'completed': validCompleted,
        'successRate': successRate,
        'hasData': dayPrayers.isNotEmpty, // Indicateur de présence de données
      });
    }

    return dailyHistory;
  }

  // Calculer le nombre attendu de prières pour une date donnée
  int _getExpectedPrayersForDate(DateTime date) {
    // Si la date est dans le futur, retourner 0
    if (date.isAfter(DateTime.now())) {
      return 0;
    }
    
    // Pour les jours passés ou actuels, retourner 5 (nombre standard de prières)
    // Dans une version plus avancée, on pourrait prendre en compte:
    // - Les jours de voyage (qasr)
    // - Les préférences utilisateur
    // - Les jours fériés religieux
    return 5;
  }

  // Méthodes d'invalidation du cache
  
  /// Invalide le cache des prières et statistiques pour un utilisateur à une date donnée
  Future<void> _invalidatePrayerCache(String userId, DateTime date) async {
    final dateKey = '${date.year}_${date.month}_${date.day}';
    
    // Invalider le cache des prières pour cette date
    await CacheService.instance.remove('prayers_${userId}_$dateKey');
    
    // Invalider le cache des statistiques
    await CacheService.instance.remove('user_stats_$userId');
  }

  /// Invalide tout le cache d'un utilisateur
  Future<void> invalidateUserCache(String userId) async {
    // Utiliser un pattern pour supprimer toutes les entrées de cet utilisateur
    await CacheService.instance.clear();
    
    // Ou plus spécifiquement, on pourrait implémenter une méthode pour supprimer par pattern
    final keys = [
      'user_data_$userId',
      'user_stats_$userId',
    ];
    
    for (final key in keys) {
      await CacheService.instance.remove(key);
    }
  }

  // Calculer la tendance avec régression linéaire simple
  String _calculateTrend(List<double> percentages, List<bool> hasDataFlags) {
    // Filtrer les données valides seulement
    List<double> validPercentages = [];
    List<int> validIndices = [];
    
    for (int i = 0; i < percentages.length; i++) {
      if (hasDataFlags[i] && percentages[i] >= 0) {
        validPercentages.add(percentages[i]);
        validIndices.add(i);
      }
    }
    
    // Il faut au moins 3 points de données valides pour calculer une tendance
    if (validPercentages.length < 3) {
      return 'stable';
    }
    
    // Régression linéaire simple: y = mx + b
    int n = validPercentages.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      double x = validIndices[i].toDouble();
      double y = validPercentages[i];
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    // Calculer la pente (coefficient de corrélation)
    double slope = (n.toDouble() * sumXY - sumX * sumY) / (n.toDouble() * sumX2 - sumX * sumX);
    
    // Déterminer la tendance basée sur la pente
    if (slope > 2.0) {
      return 'up';
    } else if (slope < -2.0) {
      return 'down';
    } else {
      return 'stable';
    }
  }
}