import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache hybride optimisé pour TaqwaTime
/// Combine cache en mémoire (LRU) et persistance locale
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._internal();
  
  CacheService._internal();

  // Cache en mémoire avec LRU
  final Map<String, CacheEntry> _memoryCache = {};
  final List<String> _lruOrder = [];
  
  // Configuration
  static const int _maxMemoryItems = 100;
  static const int _defaultTtlMinutes = 30;
  static const String _cachePrefix = 'taqwa_cache_';
  
  SharedPreferences? _prefs;

  /// Initialise le service de cache
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanExpiredCache();
  }

  /// Met en cache une valeur avec TTL optionnel
  Future<void> put<T>(
    String key, 
    T value, {
    int? ttlMinutes,
    bool persistLocal = false,
    bool compressLarge = true,
  }) async {
    final ttl = ttlMinutes ?? _defaultTtlMinutes;
    final expiry = DateTime.now().add(Duration(minutes: ttl));
    
    final serializedValue = _serialize(value);
    final shouldCompress = compressLarge && serializedValue.length > 1024;
    
    final cacheEntry = CacheEntry(
      value: serializedValue,
      expiry: expiry,
      isCompressed: shouldCompress,
    );

    // Mise en cache mémoire
    await _putInMemory(key, cacheEntry);
    
    // Persistance locale si demandée
    if (persistLocal) {
      await _putInStorage(key, cacheEntry);
    }
  }

  /// Récupère une valeur du cache
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    // Essayer d'abord le cache mémoire
    var entry = _getFromMemory(key);
    
    // Si non trouvé, essayer le stockage persistant
    if (entry == null) {
      entry = await _getFromStorage(key);
      
      // Si trouvé dans le stockage, le remettre en mémoire
      if (entry != null) {
        await _putInMemory(key, entry);
      }
    }
    
    if (entry == null || entry.isExpired) {
      if (entry?.isExpired == true) {
        await remove(key);
      }
      return defaultValue;
    }
    
    return _deserialize<T>(entry.value);
  }

  /// Vérifie si une clé existe dans le cache
  Future<bool> exists(String key) async {
    return await get(key) != null;
  }

  /// Supprime une clé du cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _lruOrder.remove(key);
    await _prefs?.remove('$_cachePrefix$key');
    await _prefs?.remove('${_cachePrefix}meta_$key');
  }

  /// Vide complètement le cache
  Future<void> clear() async {
    _memoryCache.clear();
    _lruOrder.clear();
    
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)).toList() ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  /// Optimise le cache en supprimant les entrées expirées
  Future<void> optimize() async {
    await _cleanExpiredCache();
    await _trimMemoryCache();
  }

  /// Obtient des statistiques sur le cache
  Map<String, dynamic> getStats() {
    final memorySize = _memoryCache.length;
    final expiredCount = _memoryCache.values.where((e) => e.isExpired).length;
    
    return {
      'memorySize': memorySize,
      'maxMemorySize': _maxMemoryItems,
      'expiredEntries': expiredCount,
      'memoryUsagePercent': (memorySize / _maxMemoryItems * 100).round(),
    };
  }

  // Méthodes spécialisées pour l'application

  /// Cache spécialisé pour les données de prière
  Future<void> putPrayerData(String userId, DateTime date, Map<String, dynamic> prayers) async {
    final key = 'prayers_${userId}_${_dateKey(date)}';
    await put(key, prayers, ttlMinutes: 60, persistLocal: true);
  }

  /// Récupère les données de prière en cache
  Future<Map<String, dynamic>?> getPrayerData(String userId, DateTime date) async {
    final key = 'prayers_${userId}_${_dateKey(date)}';
    return await get<Map<String, dynamic>>(key);
  }

  /// Cache spécialisé pour les statistiques utilisateur
  Future<void> putUserStats(String userId, Map<String, dynamic> stats) async {
    final key = 'user_stats_$userId';
    await put(key, stats, ttlMinutes: 15, persistLocal: true);
  }

  /// Récupère les statistiques utilisateur en cache
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    final key = 'user_stats_$userId';
    return await get<Map<String, dynamic>>(key);
  }

  /// Cache spécialisé pour les données utilisateur
  Future<void> putUserData(String userId, Map<String, dynamic> userData) async {
    final key = 'user_data_$userId';
    await put(key, userData, ttlMinutes: 120, persistLocal: true);
  }

  /// Récupère les données utilisateur en cache
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final key = 'user_data_$userId';
    return await get<Map<String, dynamic>>(key);
  }

  // Méthodes privées

  Future<void> _putInMemory(String key, CacheEntry entry) async {
    _memoryCache[key] = entry;
    _updateLruOrder(key);
    await _trimMemoryCache();
  }

  CacheEntry? _getFromMemory(String key) {
    if (_memoryCache.containsKey(key)) {
      _updateLruOrder(key);
      return _memoryCache[key];
    }
    return null;
  }

  Future<void> _putInStorage(String key, CacheEntry entry) async {
    final storageKey = '$_cachePrefix$key';
    final metaKey = '${_cachePrefix}meta_$key';
    
    // Stocker les métadonnées
    final meta = {
      'expiry': entry.expiry.millisecondsSinceEpoch,
      'isCompressed': entry.isCompressed,
    };
    
    await _prefs?.setString(metaKey, jsonEncode(meta));
    
    // Stocker la valeur (compressée si nécessaire)
    if (entry.isCompressed) {
      final compressed = gzip.encode(utf8.encode(entry.value));
      await _prefs?.setString(storageKey, base64Encode(compressed));
    } else {
      await _prefs?.setString(storageKey, entry.value);
    }
  }

  Future<CacheEntry?> _getFromStorage(String key) async {
    final storageKey = '$_cachePrefix$key';
    final metaKey = '${_cachePrefix}meta_$key';
    
    final metaString = _prefs?.getString(metaKey);
    final valueString = _prefs?.getString(storageKey);
    
    if (metaString == null || valueString == null) return null;
    
    try {
      final meta = jsonDecode(metaString) as Map<String, dynamic>;
      final expiry = DateTime.fromMillisecondsSinceEpoch(meta['expiry']);
      final isCompressed = meta['isCompressed'] ?? false;
      
      String value;
      if (isCompressed) {
        final compressed = base64Decode(valueString);
        final decompressed = gzip.decode(compressed);
        value = utf8.decode(decompressed);
      } else {
        value = valueString;
      }
      
      return CacheEntry(
        value: value,
        expiry: expiry,
        isCompressed: isCompressed,
      );
    } catch (e) {
      // Entrée corrompue, la supprimer
      await _prefs?.remove(storageKey);
      await _prefs?.remove(metaKey);
      return null;
    }
  }

  void _updateLruOrder(String key) {
    _lruOrder.remove(key);
    _lruOrder.add(key);
  }

  Future<void> _trimMemoryCache() async {
    while (_memoryCache.length > _maxMemoryItems) {
      final oldestKey = _lruOrder.removeAt(0);
      _memoryCache.remove(oldestKey);
    }
  }

  Future<void> _cleanExpiredCache() async {
    // Nettoyer le cache mémoire
    final expiredKeys = _memoryCache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _lruOrder.remove(key);
    }
    
    // Nettoyer le stockage persistant
    final allKeys = _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)).toList() ?? [];
    
    for (final key in allKeys) {
      if (key.contains('meta_')) continue;
      
      final cacheKey = key.replaceFirst(_cachePrefix, '');
      final entry = await _getFromStorage(cacheKey);
      
      if (entry?.isExpired == true) {
        await remove(cacheKey);
      }
    }
  }

  String _serialize<T>(T value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }

  T? _deserialize<T>(String value) {
    if (T == String) return value as T;
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return (value.toLowerCase() == 'true') as T?;
    
    try {
      final decoded = jsonDecode(value);
      return decoded as T;
    } catch (e) {
      return null;
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }
}

/// Entrée de cache avec métadonnées
class CacheEntry {
  final String value;
  final DateTime expiry;
  final bool isCompressed;

  const CacheEntry({
    required this.value,
    required this.expiry,
    this.isCompressed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Extension pour faciliter l'utilisation du cache
extension CacheExtension on CacheService {
  /// Cache avec auto-invalidation basée sur la fréquence d'utilisation
  Future<T> getOrPut<T>(
    String key,
    Future<T> Function() fetcher, {
    int? ttlMinutes,
    bool persistLocal = false,
  }) async {
    final cached = await get<T>(key);
    if (cached != null) return cached;
    
    final value = await fetcher();
    await put(key, value, ttlMinutes: ttlMinutes, persistLocal: persistLocal);
    return value;
  }
}