enum NotificationIntensity { low, medium, high }
enum CalculationMethod { mwl, isna, egypt, karachi, tehran, jafari }
enum Madhab { shafi, hanafi }

class UserSettingsModel {
  final String userId;
  final bool notificationsEnabled;
  final NotificationIntensity notificationIntensity;
  final String notificationSound;
  final bool vibrationEnabled;
  final int reminderInterval; // en minutes
  final int maxReminders;
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final bool useLocation;
  final double latitude;
  final double longitude;
  final String timezone;
  final Map<String, int> prayerOffsets; // minutes offset per prayer (fajr, dhuhr, asr, maghrib, isha)
  final String language; // 'fr', 'ar', 'en', 'es'

  UserSettingsModel({
    required this.userId,
    this.notificationsEnabled = true,
    this.notificationIntensity = NotificationIntensity.medium,
    this.notificationSound = 'default',
    this.vibrationEnabled = true,
    this.reminderInterval = 5,
    this.maxReminders = 3,
    this.calculationMethod = CalculationMethod.mwl,
    this.madhab = Madhab.shafi,
    this.useLocation = true,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.timezone = 'UTC',
    this.prayerOffsets = const {},
    this.language = 'fr',
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['userId'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      notificationIntensity: NotificationIntensity.values.byName(
          json['notificationIntensity'] ?? 'medium'
      ),
      notificationSound: json['notificationSound'] ?? 'default',
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      reminderInterval: json['reminderInterval'] ?? 5,
      maxReminders: json['maxReminders'] ?? 3,
      calculationMethod: CalculationMethod.values.byName(
          json['calculationMethod'] ?? 'mwl'
      ),
      madhab: Madhab.values.byName(json['madhab'] ?? 'shafi'),
      useLocation: json['useLocation'] ?? true,
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      timezone: json['timezone'] ?? 'UTC',
      prayerOffsets: json['prayerOffsets'] != null
          ? Map<String, int>.from(json['prayerOffsets'])
          : const {},
      language: json['language'] ?? 'fr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'notificationIntensity': notificationIntensity.name,
      'notificationSound': notificationSound,
      'vibrationEnabled': vibrationEnabled,
      'reminderInterval': reminderInterval,
      'maxReminders': maxReminders,
      'calculationMethod': calculationMethod.name,
      'madhab': madhab.name,
      'useLocation': useLocation,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'prayerOffsets': prayerOffsets,
      'language': language,
    };
  }

  UserSettingsModel copyWith({
    String? userId,
    bool? notificationsEnabled,
    NotificationIntensity? notificationIntensity,
    String? notificationSound,
    bool? vibrationEnabled,
    int? reminderInterval,
    int? maxReminders,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    bool? useLocation,
    double? latitude,
    double? longitude,
    String? timezone,
    Map<String, int>? prayerOffsets,
    String? language,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationIntensity: notificationIntensity ?? this.notificationIntensity,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      maxReminders: maxReminders ?? this.maxReminders,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      useLocation: useLocation ?? this.useLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      prayerOffsets: prayerOffsets ?? this.prayerOffsets,
      language: language ?? this.language,
    );
  }
}