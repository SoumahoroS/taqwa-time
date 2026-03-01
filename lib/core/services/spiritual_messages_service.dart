import 'dart:math';

class SpiritualMessage {
  final String text;
  final String reference;
  final SpiritualMessageType type;
  final PrayerContext context;

  const SpiritualMessage({
    required this.text,
    required this.reference,
    required this.type,
    required this.context,
  });
}

enum SpiritualMessageType {
  quran,
  hadith,
  dua,
}

enum PrayerContext {
  approaching,  // Quand la prière approche
  time,         // C'est l'heure de la prière
  delayed,      // En retard léger (5-15 min)
  moderate,     // En retard modéré (15-30 min)
  late,         // En retard important (30-60 min)
  critical,     // En retard critique (>60 min)
  completed,    // Prière accomplie
  missed,       // Prière manquée
}

class SpiritualMessagesService {
  static final List<SpiritualMessage> _messages = [
    // ============= MESSAGES POUR PRIÈRE QUI APPROCHE =============
    SpiritualMessage(
      text: "Et accomplissez la prière aux deux extrémités du jour et à certaines heures de la nuit. Les bonnes œuvres chassent les mauvaises.",
      reference: "Sourate Hud (11:114)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.approaching,
    ),
    SpiritualMessage(
      text: "Ô vous qui croyez ! Lorsque vous vous levez pour la prière, lavez vos visages et vos mains jusqu'aux coudes.",
      reference: "Sourate Al-Maidah (5:6)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.approaching,
    ),
    SpiritualMessage(
      text: "Préparez-vous pour rencontrer votre Seigneur avec un cœur humble et une âme pure.",
      reference: "Conseil spirituel",
      type: SpiritualMessageType.dua,
      context: PrayerContext.approaching,
    ),

    // ============= MESSAGES POUR L'HEURE DE LA PRIÈRE =============
    SpiritualMessage(
      text: "Et accomplissez la prière, car la prière préserve de la turpitude et du blâmable. Le rappel d'Allah est certes ce qu'il y a de plus grand.",
      reference: "Sourate Al-Ankabut (29:45)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.time,
    ),
    SpiritualMessage(
      text: "Gardez strictement les prières et surtout la prière médiane; et tenez-vous debout devant Allah, avec humilité.",
      reference: "Sourate Al-Baqarah (2:238)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.time,
    ),
    SpiritualMessage(
      text: "La prière est un ascension (mi'raj) pour le croyant.",
      reference: "Hadith du Prophète صلى الله عليه وسلم",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.time,
    ),
    SpiritualMessage(
      text: "La première chose dont l'homme sera jugé le Jour de la Résurrection est la prière.",
      reference: "Hadith rapporté par At-Tirmidhi",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.time,
    ),

    // ============= MESSAGES POUR RETARD LÉGER =============
    SpiritualMessage(
      text: "Et empressez-vous vers un pardon de votre Seigneur et vers un Jardin large comme les cieux et la terre.",
      reference: "Sourate Ali-Imran (3:133)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.delayed,
    ),
    SpiritualMessage(
      text: "Celui qui a manqué la prière de l'Asr, c'est comme s'il avait perdu sa famille et ses biens.",
      reference: "Hadith rapporté par Bukhari",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.delayed,
    ),
    SpiritualMessage(
      text: "Hâtez-vous vers Allah, Il vous attend avec Sa miséricorde.",
      reference: "Rappel spirituel",
      type: SpiritualMessageType.dua,
      context: PrayerContext.delayed,
    ),

    // ============= MESSAGES POUR RETARD MODÉRÉ =============
    SpiritualMessage(
      text: "Et quiconque se repent et croit et accomplit une bonne œuvre... ceux-là Allah changera leurs mauvaises actions en bonnes.",
      reference: "Sourate Al-Furqan (25:70)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.moderate,
    ),
    SpiritualMessage(
      text: "Celui qui délaisse la prière va rencontrer Allah en étant en colère contre lui et Allah sera en colère contre lui.",
      reference: "Hadith rapporté par At-Tabarani",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.moderate,
    ),
    SpiritualMessage(
      text: "Ne laissez pas le Shaytan vous éloigner de votre Seigneur. Revenez maintenant !",
      reference: "Conseil spirituel",
      type: SpiritualMessageType.dua,
      context: PrayerContext.moderate,
    ),

    // ============= MESSAGES POUR RETARD IMPORTANT =============
    SpiritualMessage(
      text: "Malheur donc, à ceux qui prient tout en négligeant (et retardant) leur prière.",
      reference: "Sourate Al-Ma'un (107:4-5)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.late,
    ),
    SpiritualMessage(
      text: "Et dis: 'Ô mon Seigneur, pardonne et fais miséricorde. C'est Toi le meilleur des miséricordieux'.",
      reference: "Sourate Al-Mu'minun (23:118)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.late,
    ),
    SpiritualMessage(
      text: "Entre l'homme et le kufr (mécréance), il y a l'abandon de la prière.",
      reference: "Hadith rapporté par Muslim",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.late,
    ),

    // ============= MESSAGES POUR RETARD CRITIQUE =============
    SpiritualMessage(
      text: "Et il leur succéda une génération qui délaissa la prière et suivit les passions. Ils se trouveront en perdition.",
      reference: "Sourate Maryam (19:59)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.critical,
    ),
    SpiritualMessage(
      text: "Qu'est-ce qui vous a amenés en Saqar (Enfer) ? Ils diront: 'Nous n'étions pas de ceux qui priaient'.",
      reference: "Sourate Al-Muddathir (74:42-43)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.critical,
    ),
    SpiritualMessage(
      text: "Il n'y a pas de religion pour celui qui n'a pas de prière.",
      reference: "Hadith du Prophète صلى الله عليه وسلم",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.critical,
    ),
    SpiritualMessage(
      text: "Revenez à Allah maintenant ! Sa porte est toujours ouverte pour le repentir sincère.",
      reference: "Rappel urgent",
      type: SpiritualMessageType.dua,
      context: PrayerContext.critical,
    ),

    // ============= MESSAGES POUR PRIÈRE ACCOMPLIE =============
    SpiritualMessage(
      text: "Et ceux qui préservent leurs prières, ceux-là sont les héritiers, qui hériteront le Firdaws où ils demeureront éternellement.",
      reference: "Sourate Al-Mu'minun (23:9-11)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.completed,
    ),
    SpiritualMessage(
      text: "Certes, Allah est avec les pieux.",
      reference: "Sourate At-Tawbah (9:4)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.completed,
    ),
    SpiritualMessage(
      text: "Celui qui prie est en conversation intime avec son Seigneur.",
      reference: "Hadith du Prophète صلى الله عليه وسلم",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.completed,
    ),
    SpiritualMessage(
      text: "Qu'Allah accepte votre prière et vous récompense par Sa grâce infinie.",
      reference: "Dua de félicitation",
      type: SpiritualMessageType.dua,
      context: PrayerContext.completed,
    ),
    SpiritualMessage(
      text: "Allahumma taqabbal minni wa barik li fima razaqtani (Ô Allah, accepte de moi et bénis-moi dans ce que Tu m'as accordé).",
      reference: "Dua après la prière",
      type: SpiritualMessageType.dua,
      context: PrayerContext.completed,
    ),

    // ============= MESSAGES POUR PRIÈRE MANQUÉE =============
    SpiritualMessage(
      text: "Et quiconque fait le mal ou se fait du tort à lui-même, puis demande pardon à Allah, trouvera Allah Pardonneur et Miséricordieux.",
      reference: "Sourate An-Nisa (4:110)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.missed,
    ),
    SpiritualMessage(
      text: "Dis: 'Ô Mes serviteurs qui avez commis des excès à votre propre détriment, ne désespérez pas de la miséricorde d'Allah'.",
      reference: "Sourate Az-Zumar (39:53)",
      type: SpiritualMessageType.quran,
      context: PrayerContext.missed,
    ),
    SpiritualMessage(
      text: "Celui qui oublie une prière ou qui dort, qu'il la rattrape dès qu'il s'en souvient. Il n'y a d'autre expiation que cela.",
      reference: "Hadith rapporté par Bukhari et Muslim",
      type: SpiritualMessageType.hadith,
      context: PrayerContext.missed,
    ),
  ];

  // Messages spéciaux pour des prières spécifiques
  static final Map<String, List<SpiritualMessage>> _specificPrayerMessages = {
    'Fajr': [
      SpiritualMessage(
        text: "Et c'est Lui qui a fait alterner la nuit et le jour pour quiconque veut se rappeler ou veut être reconnaissant.",
        reference: "Sourate Al-Furqan (25:62)",
        type: SpiritualMessageType.quran,
        context: PrayerContext.time,
      ),
      SpiritualMessage(
        text: "Les deux rak'ahs du Fajr valent mieux que ce monde et ce qu'il contient.",
        reference: "Hadith rapporté par Muslim",
        type: SpiritualMessageType.hadith,
        context: PrayerContext.time,
      ),
    ],
    'Dhuhr': [
      SpiritualMessage(
        text: "C'est Lui qui a créé les cieux et la terre en six jours, puis Il S'est établi sur le Trône.",
        reference: "Sourate Al-Hadid (57:4)",
        type: SpiritualMessageType.quran,
        context: PrayerContext.time,
      ),
    ],
    'Asr': [
      SpiritualMessage(
        text: "Et par le temps ! L'homme est certes, en perdition, sauf ceux qui croient et accomplissent les bonnes œuvres.",
        reference: "Sourate Al-Asr (103:1-3)",
        type: SpiritualMessageType.quran,
        context: PrayerContext.time,
      ),
    ],
    'Maghrib': [
      SpiritualMessage(
        text: "Gloire et pureté à ton Seigneur, le Seigneur de la puissance. Il est au-dessus de ce qu'ils décrivent !",
        reference: "Sourate As-Saffat (37:180)",
        type: SpiritualMessageType.quran,
        context: PrayerContext.time,
      ),
    ],
    'Isha': [
      SpiritualMessage(
        text: "Et parmi Ses signes il y a votre sommeil la nuit et le jour, et aussi votre quête de Sa grâce.",
        reference: "Sourate Ar-Rum (30:23)",
        type: SpiritualMessageType.quran,
        context: PrayerContext.time,
      ),
    ],
  };

  static final Random _random = Random();

  /// Obtient un message spirituel selon le contexte de la prière
  static SpiritualMessage getMessageForContext(
    PrayerContext context, {
    String? prayerName,
  }) {
    // Chercher d'abord dans les messages spécifiques à la prière
    if (prayerName != null && _specificPrayerMessages.containsKey(prayerName)) {
      final specificMessages = _specificPrayerMessages[prayerName]!
          .where((msg) => msg.context == context)
          .toList();
      
      if (specificMessages.isNotEmpty) {
        return specificMessages[_random.nextInt(specificMessages.length)];
      }
    }

    // Sinon, chercher dans les messages généraux
    final contextMessages = _messages
        .where((msg) => msg.context == context)
        .toList();

    if (contextMessages.isEmpty) {
      // Fallback vers un message général si aucun contexte spécifique n'est trouvé
      return _messages[_random.nextInt(_messages.length)];
    }

    return contextMessages[_random.nextInt(contextMessages.length)];
  }

  /// Détermine le contexte selon le timing de la prière
  static PrayerContext getContextFromTiming({
    required DateTime scheduledTime,
    required DateTime currentTime,
  }) {
    final difference = currentTime.difference(scheduledTime);
    final minutesLate = difference.inMinutes;
    final minutesEarly = -minutesLate;

    if (minutesEarly > 0) {
      return PrayerContext.approaching;
    } else if (minutesLate <= 5) {
      return PrayerContext.time;
    } else if (minutesLate <= 15) {
      return PrayerContext.delayed;
    } else if (minutesLate <= 30) {
      return PrayerContext.moderate;
    } else if (minutesLate <= 60) {
      return PrayerContext.late;
    } else {
      return PrayerContext.critical;
    }
  }

  /// Obtient un message pour une prière accomplie
  static SpiritualMessage getCompletedMessage({String? prayerName}) {
    return getMessageForContext(PrayerContext.completed, prayerName: prayerName);
  }

  /// Obtient un message pour une prière manquée
  static SpiritualMessage getMissedMessage({String? prayerName}) {
    return getMessageForContext(PrayerContext.missed, prayerName: prayerName);
  }

  /// Obtient l'emoji approprié selon le type de message
  static String getTypeEmoji(SpiritualMessageType type) {
    switch (type) {
      case SpiritualMessageType.quran:
        return '📖';
      case SpiritualMessageType.hadith:
        return '🤲';
      case SpiritualMessageType.dua:
        return '🤍';
    }
  }

  /// Obtient la couleur appropriée selon le contexte
  static String getContextColor(PrayerContext context) {
    switch (context) {
      case PrayerContext.approaching:
        return '#2196F3'; // Bleu
      case PrayerContext.time:
        return '#4CAF50'; // Vert
      case PrayerContext.delayed:
        return '#FF9800'; // Orange
      case PrayerContext.moderate:
        return '#FF5722'; // Orange foncé
      case PrayerContext.late:
        return '#F44336'; // Rouge
      case PrayerContext.critical:
        return '#B71C1C'; // Rouge foncé
      case PrayerContext.completed:
        return '#4CAF50'; // Vert
      case PrayerContext.missed:
        return '#9E9E9E'; // Gris
    }
  }
}