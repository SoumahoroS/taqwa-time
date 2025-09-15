import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Cache intelligent multi-niveaux
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _cacheTimers = {};
  
  // Métriques de performance
  final BehaviorSubject<PerformanceMetrics> _metricsSubject = 
      BehaviorSubject<PerformanceMetrics>.seeded(PerformanceMetrics());
  
  // Configuration du cache
  static const Duration _defaultCacheDuration = Duration(minutes: 15);
  static const int _maxMemoryCacheSize = 100;
  
  Stream<PerformanceMetrics> get metrics => _metricsSubject.stream;
  
  Future<void> initialize() async {
    print("🚀 Initialisation du service de performance");
    
    _startPerformanceMonitoring();
    await _loadCacheFromDisk();
    
    print("✅ Service de performance initialisé");
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      _updatePerformanceMetrics();
      _cleanupExpiredCache();
    });
  }

  Future<T?> getFromCache<T>(
    String key, {
    Duration? ttl,
    bool useMemoryOnly = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. Vérifier le cache mémoire
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (!entry.isExpired) {
          _updateMetrics(cacheHit: true, operation: 'memory_read', duration: stopwatch.elapsed);
          return entry.data as T?;
        } else {
          _memoryCache.remove(key);
          _cacheTimers[key]?.cancel();
          _cacheTimers.remove(key);
        }
      }
      
      if (useMemoryOnly) {
        _updateMetrics(cacheHit: false, operation: 'memory_read', duration: stopwatch.elapsed);
        return null;
      }
      
      // 2. Vérifier le cache disque
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_$key');
      
      if (cachedJson != null) {
        final cacheData = CacheEntry.fromJson(cachedJson);
        if (!cacheData.isExpired) {
          // Remettre en cache mémoire
          _setMemoryCache(key, cacheData.data, cacheData.ttl);
          _updateMetrics(cacheHit: true, operation: 'disk_read', duration: stopwatch.elapsed);
          return cacheData.data as T?;
        } else {
          // Nettoyer le cache expiré
          prefs.remove('cache_$key');
        }
      }
      
      _updateMetrics(cacheHit: false, operation: 'cache_miss', duration: stopwatch.elapsed);
      return null;
    } catch (e) {
      print("❌ Erreur lecture cache $key: $e");
      _updateMetrics(cacheHit: false, operation: 'cache_error', duration: stopwatch.elapsed);
      return null;
    }
  }

  Future<void> setCache<T>(
    String key,
    T data, {
    Duration? ttl,
    bool memoryOnly = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final effectiveTtl = ttl ?? _defaultCacheDuration;
      
      // 1. Mise en cache mémoire
      _setMemoryCache(key, data, effectiveTtl);
      
      if (!memoryOnly) {
        // 2. Mise en cache disque (asynchrone)
        _setCacheDiskAsync(key, data, effectiveTtl);
      }
      
      _updateMetrics(cacheHit: false, operation: 'cache_write', duration: stopwatch.elapsed);
    } catch (e) {
      print("❌ Erreur écriture cache $key: $e");
      _updateMetrics(cacheHit: false, operation: 'cache_error', duration: stopwatch.elapsed);
    }
  }

  void _setMemoryCache<T>(String key, T data, Duration ttl) {
    // Nettoyer le cache si trop plein
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictOldestCacheEntries();
    }
    
    final entry = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl,
    );
    
    _memoryCache[key] = entry;
    
    // Programmer la suppression automatique
    _cacheTimers[key]?.cancel();
    _cacheTimers[key] = Timer(ttl, () {
      _memoryCache.remove(key);
      _cacheTimers.remove(key);
    });
  }

  Future<void> _setCacheDiskAsync<T>(String key, T data, Duration ttl) async {
    // Exécuter en isolate pour éviter de bloquer l'UI
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = CacheEntry(
        data: data,
        createdAt: DateTime.now(),
        ttl: ttl,
      );
      
      await prefs.setString('cache_$key', entry.toJson());
    } catch (e) {
      print("❌ Erreur cache disque $key: $e");
    }
  }

  void _evictOldestCacheEntries() {
    final entries = _memoryCache.entries.toList();
    entries.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
    
    final toRemove = entries.take(_maxMemoryCacheSize ~/ 4).map((e) => e.key);
    for (final key in toRemove) {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
    }
  }

  void _cleanupExpiredCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
    }
  }

  Future<void> _loadCacheFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
      
      int loadedCount = 0;
      for (final fullKey in keys) {
        final key = fullKey.substring(6); // Remove 'cache_' prefix
        final cachedJson = prefs.getString(fullKey);
        
        if (cachedJson != null) {
          try {
            final entry = CacheEntry.fromJson(cachedJson);
            if (!entry.isExpired) {
              _setMemoryCache(key, entry.data, entry.ttl);
              loadedCount++;
            } else {
              prefs.remove(fullKey);
            }
          } catch (e) {
            print("❌ Erreur chargement cache $key: $e");
            prefs.remove(fullKey);
          }
        }
      }
      
      print("📋 Cache chargé: $loadedCount entrées");
    } catch (e) {
      print("❌ Erreur chargement cache disque: $e");
    }
  }

  void _updatePerformanceMetrics() {
    final currentMetrics = _metricsSubject.value;
    final newMetrics = currentMetrics.copyWith(
      cacheSize: _memoryCache.length,
      lastUpdate: DateTime.now(),
    );
    
    _metricsSubject.add(newMetrics);
  }

  void _updateMetrics({
    required bool cacheHit,
    required String operation,
    required Duration duration,
  }) {
    final currentMetrics = _metricsSubject.value;
    final newMetrics = currentMetrics.copyWith(
      totalOperations: currentMetrics.totalOperations + 1,
      cacheHits: currentMetrics.cacheHits + (cacheHit ? 1 : 0),
      averageResponseTime: _calculateNewAverage(
        currentMetrics.averageResponseTime,
        duration,
        currentMetrics.totalOperations,
      ),
      lastUpdate: DateTime.now(),
    );
    
    _metricsSubject.add(newMetrics);
  }

  Duration _calculateNewAverage(Duration currentAvg, Duration newValue, int count) {
    if (count == 0) return newValue;
    
    final currentMs = currentAvg.inMilliseconds;
    final newMs = newValue.inMilliseconds;
    final avgMs = ((currentMs * (count - 1)) + newMs) ~/ count;
    
    return Duration(milliseconds: avgMs);
  }

  // Opérations avec cache automatique
  Future<T> memoize<T>(
    String key,
    Future<T> Function() computation, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await getFromCache<T>(key, ttl: ttl);
      if (cached != null) {
        return cached;
      }
    }
    
    print("🔄 Calcul de $key");
    final result = await computation();
    await setCache(key, result, ttl: ttl);
    
    return result;
  }

  // Préchargement intelligent
  Future<void> preloadCache(Map<String, Future Function()> preloadTasks) async {
    final futures = <Future>[];
    
    for (final entry in preloadTasks.entries) {
      futures.add(_preloadTask(entry.key, entry.value));
    }
    
    await Future.wait(futures);
    print("✅ Préchargement terminé: ${preloadTasks.length} tâches");
  }

  Future<void> _preloadTask(String key, Future Function() task) async {
    try {
      final cached = await getFromCache(key, useMemoryOnly: true);
      if (cached == null) {
        final result = await task();
        await setCache(key, result, memoryOnly: true);
      }
    } catch (e) {
      print("❌ Erreur préchargement $key: $e");
    }
  }

  // Nettoyage et maintenance
  Future<void> clearCache({String? pattern}) async {
    if (pattern != null) {
      final keysToRemove = _memoryCache.keys.where((key) => key.contains(pattern));
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        _cacheTimers[key]?.cancel();
        _cacheTimers.remove(key);
      }
    } else {
      _memoryCache.clear();
      for (final timer in _cacheTimers.values) {
        timer.cancel();
      }
      _cacheTimers.clear();
    }
    
    // Nettoyer le cache disque aussi
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('cache_') && 
      (pattern == null || key.contains(pattern))
    );
    
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    print("🗑️ Cache nettoyé" + (pattern != null ? " (pattern: $pattern)" : ""));
  }

  // Statistiques détaillées
  Map<String, dynamic> getCacheStats() {
    final metrics = _metricsSubject.value;
    
    return {
      'memoryCache': {
        'size': _memoryCache.length,
        'maxSize': _maxMemoryCacheSize,
        'usage': (_memoryCache.length / _maxMemoryCacheSize * 100).round(),
      },
      'performance': {
        'totalOperations': metrics.totalOperations,
        'cacheHits': metrics.cacheHits,
        'hitRate': metrics.hitRate,
        'averageResponseTime': '${metrics.averageResponseTime.inMilliseconds}ms',
      },
      'lastUpdate': metrics.lastUpdate.toString(),
    };
  }

  void dispose() {
    print("🛑 Arrêt du service de performance");
    
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
    _memoryCache.clear();
    _metricsSubject.close();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  String toJson() {
    return jsonEncode({
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'ttlMs': ttl.inMilliseconds,
    });
  }

  static CacheEntry fromJson(String json) {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return CacheEntry(
        data: data['data'],
        createdAt: DateTime.parse(data['createdAt']),
        ttl: Duration(milliseconds: data['ttlMs']),
      );
    } catch (e) {
      throw FormatException('Invalid cache entry JSON: $e');
    }
  }
}

class PerformanceMetrics {
  final int totalOperations;
  final int cacheHits;
  final Duration averageResponseTime;
  final int cacheSize;
  final DateTime lastUpdate;

  PerformanceMetrics({
    this.totalOperations = 0,
    this.cacheHits = 0,
    this.averageResponseTime = Duration.zero,
    this.cacheSize = 0,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  double get hitRate => totalOperations > 0 ? (cacheHits / totalOperations * 100) : 0.0;

  PerformanceMetrics copyWith({
    int? totalOperations,
    int? cacheHits,
    Duration? averageResponseTime,
    int? cacheSize,
    DateTime? lastUpdate,
  }) {
    return PerformanceMetrics(
      totalOperations: totalOperations ?? this.totalOperations,
      cacheHits: cacheHits ?? this.cacheHits,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      cacheSize: cacheSize ?? this.cacheSize,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}