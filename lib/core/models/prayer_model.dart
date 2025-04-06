enum PrayerStatus { onTime, late, missed, notYet }
enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

class PrayerModel {
  final String id;
  final String userId;
  final PrayerType type;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final PrayerStatus status;

  PrayerModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.scheduledTime,
    this.completedTime,
    required this.status,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'],
      userId: json['userId'],
      type: PrayerType.values.byName(json['type']),
      scheduledTime: DateTime.parse(json['scheduledTime']),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      status: PrayerStatus.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status.name,
    };
  }
}