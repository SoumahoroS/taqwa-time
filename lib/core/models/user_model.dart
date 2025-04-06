class UserModel {
  final String id;
  final String email;
  final String name;
  final double latitude;
  final double longitude;
  final String timezone;
  final Map<String, dynamic> notificationSettings;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.notificationSettings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timezone: json['timezone'],
      notificationSettings: json['notificationSettings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'notificationSettings': notificationSettings,
    };
  }
}