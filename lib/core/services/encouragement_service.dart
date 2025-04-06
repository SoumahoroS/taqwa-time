// lib/core/services/encouragement_service.dart

import 'dart:math';
import '../models/prayer_model.dart';

class EncouragementService {
  // Singleton
  static final EncouragementService _instance = EncouragementService._internal();
  factory EncouragementService() => _instance;
  EncouragementService._internal();

  final Random _random = Random();

  // Obtenir un message d'encouragement basé sur les statistiques
  String getEncouragementMessage({
    required Map<PrayerType, PrayerStatus> todayPrayers,
    required int streak,
    required double weeklyCompletion,
    required String trend,
  }) {
    // Calculer le pourcentage de complétion pour aujourd'hui
    final completedCount = todayPrayers.values
        .where((status) => status == PrayerStatus.onTime || status == PrayerStatus.late)
        .length;
    final totalCount = todayPrayers.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

    // Déterminer quel type de message est le plus approprié
    if (completionRate == 100) {
      return _getPerfectCompletionMessage(streak);
    } else if (completionRate >= 80) {
      return _getHighCompletionMessage();
    } else if (completionRate >= 50) {
      return _getMediumCompletionMessage();
    } else if (completionRate > 0) {
      return _getLowCompletionMessage();
    } else {
      return _getNoCompletionMessage();
    }
  }

  // Messages pour 100% de complétion
  String _getPerfectCompletionMessage(int streak) {
    final messages = [
      "Alhamdulillah! Vous avez accompli toutes vos prières aujourd'hui.",
      "SubhanAllah, votre dévotion est admirable. Toutes vos prières sont accomplies!",
      "Qu'Allah accepte vos prières. Vous avez réussi à toutes les accomplir!",
      "Excellent! Vous maintenez votre engagement spirituel.",
      "MashaAllah! Votre constance dans la prière plaît à Allah."
    ];

    // Ajouter des messages spécifiques au streak
    if (streak >= 5) {
      messages.add("MashaAllah! Vous êtes à $streak jours consécutifs de prières complètes. Une récompense immense vous attend!");
      messages.add("$streak jours de constance! Le Prophète (SAW) a dit: 'Les actes les plus aimés d'Allah sont ceux pratiqués avec constance, même s'ils sont petits.'");
    } else if (streak >= 3) {
      messages.add("$streak jours consécutifs! Votre dévotion est sur la bonne voie.");
      messages.add("$streak jours de régularité dans vos prières - qu'Allah vous récompense!");
    } else if (streak > 0) {
      messages.add("C'est le début d'une belle série de prières! Continuez ainsi!");
    }

    return messages[_random.nextInt(messages.length)];
  }

  // Messages pour 80%+ de complétion
  String _getHighCompletionMessage() {
    final messages = [
      "Presque parfait! N'oubliez pas de compléter les prières restantes.",
      "Vous êtes sur la bonne voie. Allah apprécie votre effort.",
      "MashaAllah! Continuez à maintenir ce haut niveau de dévotion.",
      "Votre régularité est exemplaire. Visez toujours la perfection dans vos actes d'adoration.",
      "Excellent progrès! Essayez d'atteindre la perfection demain, insha'Allah."
    ];

    return messages[_random.nextInt(messages.length)];
  }

  // Messages pour 50-79% de complétion
  String _getMediumCompletionMessage() {
    final messages = [
      "Vous progressez bien! Chaque prière est un pas vers Allah.",
      "Continuez vos efforts! Allah voit votre persévérance.",
      "Votre dévotion est notée. Efforcez-vous d'être encore plus régulier.",
      "Vous êtes sur le bon chemin spirituel. Chaque prière compte énormément.",
      "La constance est la clé. Efforcez-vous d'améliorer votre régularité."
    ];

    return messages[_random.nextInt(messages.length)];
  }

  // Messages pour 1-49% de complétion
  String _getLowCompletionMessage() {
    final messages = [
      "Chaque prière accomplie est précieuse. Efforcez-vous d'en faire plus.",
      "Ne sous-estimez pas la valeur de chaque prière, même si vous en avez manqué certaines.",
      "Allah est Le Tout Miséricordieux. Chaque effort pour améliorer votre pratique est récompensé.",
      "Avancez pas à pas. Même une petite amélioration est significative.",
      "La prière est un lien direct avec Allah. Renforcez ce lien jour après jour."
    ];

    return messages[_random.nextInt(messages.length)];
  }

  // Messages pour 0% de complétion
  String _getNoCompletionMessage() {
    final messages = [
      "Il n'est jamais trop tard pour commencer. La porte du repentir est toujours ouverte.",
      "Chaque jour est une nouvelle opportunité de se rapprocher d'Allah.",
      "La prochaine prière est une chance de renouer votre lien avec Allah.",
      "La prière apporte la paix intérieure. N'hésitez pas à commencer dès maintenant.",
      "Le Prophète (SAW) a dit: 'Entre l'homme et la mécréance, il y a l'abandon de la prière.' Prenez soin de vos prières."
    ];

    return messages[_random.nextInt(messages.length)];
  }

  // Messages spécifiques pour les streaks
  String getStreakMessage(int streak) {
    if (streak >= 30) {
      return "MashaAllah! $streak jours de constance. Le Paradis se mérite par la constance des bonnes œuvres!";
    } else if (streak >= 15) {
      return "Félicitations pour vos $streak jours de régularité. Qu'Allah facilite votre parcours spirituel!";
    } else if (streak >= 7) {
      return "Une semaine complète de régularité! Qu'Allah vous accorde Sa satisfaction.";
    } else if (streak >= 3) {
      return "3 jours consécutifs! Persévérez, la constance est la clé du succès spirituel.";
    } else if (streak > 0) {
      return "Chaque jour compte! Continuez à maintenir cette régularité.";
    } else {
      return "Chaque jour est une nouvelle opportunité de commencer une série de bonnes actions.";
    }
  }

  // Citations islamiques sur l'importance de la prière
  String getIslamicQuote() {
    final quotes = [
      "Le Prophète (SAW) a dit: 'La différence entre nous et eux (les mécréants), c'est la prière. Celui qui l'abandonne a certes mécru.'",
      "Allah dit dans le Coran: 'Accomplis la prière, car la prière préserve de la turpitude et du blâmable.' [29:45]",
      "Le Prophète (SAW) a dit: 'La première chose sur laquelle le serviteur sera jugé le Jour de la Résurrection sera la prière.'",
      "Allah dit: 'Certes, la prière est prescrite aux croyants à des heures déterminées.' [4:103]",
      "Le Prophète (SAW) a dit: 'La clé du Paradis est la prière, et la clé de la prière est la purification.'",
      "Le Prophète (SAW) a dit: 'Les actes les plus aimés d'Allah sont ceux qui sont pratiqués avec constance, même s'ils sont peu nombreux.'",
      "Allah dit dans le Coran: 'Sois constant dans la prière, car la prière éloigne de la turpitude et du blâmable.' [29:45]",
      "Le Prophète (SAW) a dit: 'Quiconque garde assidûment les cinq prières quotidiennes, elles lui serviront de lumière, de preuve et de salut le Jour de la Résurrection.'"
    ];

    return quotes[_random.nextInt(quotes.length)];
  }

  // Messages de motivation basés sur la tendance
  String getTrendMessage(String trend, double weeklyCompletion) {
    if (trend == 'up') {
      return "Vos performances s'améliorent! Continuez sur cette belle lancée, qu'Allah vous récompense.";
    } else if (trend == 'down' && weeklyCompletion > 30) {
      return "Votre régularité semble diminuer. Renouvelez votre intention et votre engagement.";
    } else if (trend == 'down') {
      return "N'abandonnez pas! Chaque prière vous rapproche d'Allah. Persévérez.";
    } else {
      return "Votre régularité est stable. Visez toujours plus haut dans votre dévotion.";
    }
  }
}