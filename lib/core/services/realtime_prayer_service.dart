import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/prayer_model.dart';
import 'prayer_time_service.dart';
import 'spiritual_messages_service.dart';
import 'auth_service.dart';
import '../repositories/settings_repository.dart';
import '../../main.dart' show globalNotificationService;

class RealtimePrayerService {
  static final RealtimePrayerService _instance = RealtimePrayerService._internal();
  factory RealtimePrayerService() => _instance;
  RealtimePrayerService._internal();

  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  AuthService? _authService;
  SettingsRepository? _settingsRepository;
  
  // Méthode pour injecter les dépendances
  void initialize({
    required AuthService authService,
    required SettingsRepository settingsRepository,
  }) {
    _authService = authService;
    _settingsRepository = settingsRepository;
  }
  
  // Streams pour la réactivité temps réel
  final BehaviorSubject<List<PrayerModel>> _prayersSubject = BehaviorSubject<List<PrayerModel>>();
  final BehaviorSubject<PrayerModel?> _currentPrayerSubject = BehaviorSubject<PrayerModel?>();
  final BehaviorSubject<Duration> _timeUntilNextPrayerSubject = BehaviorSubject<Duration>();
  final BehaviorSubject<SpiritualMessage> _currentMessageSubject = BehaviorSubject<SpiritualMessage>();
  final BehaviorSubject<bool> _isConnectedSubject = BehaviorSubject<bool>.seeded(true);
  
  // Timers pour les mises à jour automatiques
  Timer? _updateTimer;
  Timer? _messageTimer;
  Timer? _prayerCheckTimer;
  
  // Cache intelligent
  List<PrayerModel>? _cachedPrayers;
  DateTime? _cacheDate;
  
  // Streams publics
  Stream<List<PrayerModel>> get prayers => _prayersSubject.stream.distinct();
  Stream<PrayerModel?> get currentPrayer => _currentPrayerSubject.stream.distinct();
  Stream<Duration> get timeUntilNextPrayer => _timeUntilNextPrayerSubject.stream.distinct();
  Stream<SpiritualMessage> get currentMessage => _currentMessageSubject.stream.distinct();
  Stream<bool> get connectionStatus => _isConnectedSubject.stream.distinct();

  // Getters pour accès synchrone
  List<PrayerModel>? get currentPrayers => _prayersSubject.valueOrNull;
  PrayerModel? get nextPrayer => _currentPrayerSubject.valueOrNull;
  bool get isConnected => _isConnectedSubject.value;

  Future<void> start() async {
    print("🚀 Démarrage du service temps réel");
    
    await _setupConnectivityMonitoring();
    await _loadInitialData();
    _startPeriodicUpdates();
    _startMessageRotation();
    _startPrayerMonitoring();
    
    print("✅ Service temps réel démarré");
  }

  Future<void> _setupConnectivityMonitoring() async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool connected = result != ConnectivityResult.none;
      _isConnectedSubject.add(connected);
      
      if (connected) {
        print("🌐 Connexion rétablie - synchronisation");
        _syncData();
      } else {
        print("📴 Connexion perdue - mode hors ligne");
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final now = DateTime.now();
      
      // Vérifier si l'utilisateur est connecté
      if (_authService?.currentUser == null) {
        print("⚠️ Aucun utilisateur connecté pour charger les prières");
        return;
      }
      
      final userId = _authService!.currentUser!.uid;
      final prayers = await _prayerTimeService.createDailyPrayers(
        userId: userId,
        date: now
      );
      
      _cachedPrayers = prayers;
      _cacheDate = now;
      _prayersSubject.add(prayers);
      
      await _updateCurrentPrayer();
      await _updateSpiritualMessage();
      
      print("📅 Données initiales chargées: ${prayers.length} prières");
    } catch (e) {
      print("❌ Erreur lors du chargement initial: $e");
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateTimeUntilNextPrayer();
      _checkForPrayerChanges();
    });
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _updateSpiritualMessage();
    });
  }

  void _startPrayerMonitoring() {
    _prayerCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkPrayerStatus();
    });
  }

  Future<void> _updateCurrentPrayer() async {
    try {
      final prayers = _cachedPrayers ?? [];
      final now = DateTime.now();
      
      PrayerModel? nextPrayer;
      for (var prayer in prayers) {
        if (prayer.scheduledTime.isAfter(now) && 
            prayer.status == PrayerStatus.notYet) {
          nextPrayer = prayer;
          break;
        }
      }
      
      _currentPrayerSubject.add(nextPrayer);
      await _updateTimeUntilNextPrayer();
    } catch (e) {
      print("❌ Erreur mise à jour prière courante: $e");
    }
  }

  Future<void> _updateTimeUntilNextPrayer() async {
    final nextPrayer = _currentPrayerSubject.valueOrNull;
    if (nextPrayer != null) {
      final now = DateTime.now();
      final timeUntil = nextPrayer.scheduledTime.difference(now);
      _timeUntilNextPrayerSubject.add(timeUntil);
    }
  }

  Future<void> _updateSpiritualMessage() async {
    try {
      final nextPrayer = _currentPrayerSubject.valueOrNull;
      final now = DateTime.now();
      
      SpiritualMessage message;
      
      if (nextPrayer != null) {
        final context = SpiritualMessagesService.getContextFromTiming(
          scheduledTime: nextPrayer.scheduledTime,
          currentTime: now
        );
        
        message = SpiritualMessagesService.getMessageForContext(
          context,
          prayerName: _prayerTimeService.getPrayerName(nextPrayer.type)
        );
      } else {
        message = SpiritualMessagesService.getMessageForContext(
          PrayerContext.completed
        );
      }
      
      _currentMessageSubject.add(message);
    } catch (e) {
      print("❌ Erreur mise à jour message: $e");
    }
  }

  Future<void> _checkForPrayerChanges() async {
    final now = DateTime.now();
    
    if (_cacheDate == null || 
        _cacheDate!.day != now.day ||
        _cacheDate!.month != now.month ||
        _cacheDate!.year != now.year) {
      await refreshPrayers();
    }
  }

  Future<void> _checkPrayerStatus() async {
    final prayers = _cachedPrayers;
    if (prayers == null) return;
    
    final now = DateTime.now();
    bool hasChanges = false;
    final updatedPrayers = <PrayerModel>[];
    
    for (var prayer in prayers) {
      if (now.isAfter(prayer.scheduledTime) && 
          prayer.status == PrayerStatus.notYet) {
        final missedPrayer = prayer.markAsMissed();
        updatedPrayers.add(missedPrayer);
        hasChanges = true;
        
        await _handleMissedPrayer(missedPrayer);
      } else {
        updatedPrayers.add(prayer);
      }
    }
    
    if (hasChanges) {
      _cachedPrayers = updatedPrayers;
      _prayersSubject.add(List.from(updatedPrayers));
      await _updateCurrentPrayer();
      await _updateSpiritualMessage();
    }
  }

  Future<void> _handleMissedPrayer(PrayerModel prayer) async {
    print("⚠️ Prière manquée: ${_prayerTimeService.getPrayerName(prayer.type)}");
  }

  Future<void> refreshPrayers() async {
    try {
      print("🔄 Actualisation des prières");
      final now = DateTime.now();
      
      // Vérifier si l'utilisateur est connecté
      if (_authService?.currentUser == null) {
        print("⚠️ Aucun utilisateur connecté pour actualiser les prières");
        return;
      }
      
      final userId = _authService!.currentUser!.uid;
      final prayers = await _prayerTimeService.createDailyPrayers(
        userId: userId, 
        date: now
      );
      
      _cachedPrayers = prayers;
      _cacheDate = now;
      _prayersSubject.add(prayers);
      
      await _updateCurrentPrayer();
      await _updateSpiritualMessage();
      
      print("✅ Prières actualisées");
    } catch (e) {
      print("❌ Erreur actualisation: $e");
    }
  }

  Future<void> markPrayerCompleted(String prayerId) async {
    final prayers = _cachedPrayers;
    if (prayers == null) return;
    
    final prayerIndex = prayers.indexWhere((p) => p.id == prayerId);
    if (prayerIndex == -1) return;
    
    final completedPrayer = prayers[prayerIndex].markAsCompleted();
    prayers[prayerIndex] = completedPrayer;
    
    _cachedPrayers = List.from(prayers);
    _prayersSubject.add(List.from(prayers));
    await _updateCurrentPrayer();
    await _updateSpiritualMessage();
    
    // Arrêter les notifications pour cette prière
    if (globalNotificationService != null) {
      final notificationId = globalNotificationService!.generateNotificationId(prayerId);
      await globalNotificationService!.resetReminderCount(notificationId);
    }
    
    print("✅ Prière marquée comme accomplie: ${completedPrayer.type.name}");
  }

  Future<void> scheduleTodayPrayers() async {
    final prayers = _cachedPrayers;
    if (prayers == null) return;
    
    // Vérifier si l'utilisateur est connecté
    if (_authService?.currentUser == null) {
      print("⚠️ Aucun utilisateur connecté pour programmer les notifications");
      return;
    }
    
    final userId = _authService!.currentUser!.uid;
    
    // Vérifier les paramètres de notification de l'utilisateur
    final userSettings = await _settingsRepository?.getUserSettings(userId);
    
    if (userSettings?.notificationsEnabled != true) {
      print("🔕 Notifications désactivées par l'utilisateur");
      return;
    }
    
    print("📅 Programmation des notifications pour aujourd'hui");
    
    if (globalNotificationService != null) {
      for (var prayer in prayers) {
        if (prayer.status == PrayerStatus.notYet) {
          final nextPrayerIndex = prayers.indexWhere(
            (p) => p.scheduledTime.isAfter(prayer.scheduledTime)
          );
          final nextPrayer = nextPrayerIndex != -1 ? prayers[nextPrayerIndex] : null;
          
          await globalNotificationService!.schedulePrayerNotificationSequence(
            prayerId: prayer.id,
            prayerType: prayer.type,
            prayerName: _prayerTimeService.getPrayerName(prayer.type),
            scheduledTime: prayer.scheduledTime,
            nextPrayerTime: nextPrayer?.scheduledTime,
            nextPrayerName: nextPrayer != null ? _prayerTimeService.getPrayerName(nextPrayer.type) : '',
            userId: userId,
          );
        }
      }
      print("✅ Notifications programmées pour ${prayers.length} prières");
    } else {
      print("⚠️ Service de notification non disponible");
    }
  }

  Future<void> _syncData() async {
    if (!_isConnectedSubject.value) return;
    
    try {
      await refreshPrayers();
      print("🔄 Synchronisation terminée");
    } catch (e) {
      print("❌ Erreur synchronisation: $e");
    }
  }

  Stream<String> get formattedTimeUntilNext {
    return _timeUntilNextPrayerSubject.stream.map((duration) {
      if (duration.isNegative) return "En retard";
      
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      
      if (hours > 0) {
        return "${hours}h ${minutes}m";
      } else if (minutes > 0) {
        return "${minutes}m ${seconds}s";
      } else {
        return "${seconds}s";
      }
    });
  }

  Stream<Map<String, dynamic>> get prayerStats {
    return _prayersSubject.stream.map((prayers) {
      final completed = prayers.where((p) => p.status == PrayerStatus.onTime || p.status == PrayerStatus.late).length;
      final missed = prayers.where((p) => p.status == PrayerStatus.missed).length;
      final remaining = prayers.where((p) => p.status == PrayerStatus.notYet).length;
      
      return {
        'completed': completed,
        'missed': missed,
        'remaining': remaining,
        'total': prayers.length,
        'completionRate': prayers.isNotEmpty ? (completed / prayers.length * 100).round() : 0
      };
    });
  }

  void dispose() {
    print("🛑 Arrêt du service temps réel");
    
    _updateTimer?.cancel();
    _messageTimer?.cancel();
    _prayerCheckTimer?.cancel();
    
    _prayersSubject.close();
    _currentPrayerSubject.close();
    _timeUntilNextPrayerSubject.close();
    _currentMessageSubject.close();
    _isConnectedSubject.close();
  }
}