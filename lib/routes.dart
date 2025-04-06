import 'package:flutter/material.dart';
import 'features/authentication/presentation/screens/auth_wrapper.dart';
import 'features/authentication/presentation/screens/home_screen.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/presentation/screens/prayer_tracking_screen.dart';
import 'features/authentication/presentation/screens/profile_screen.dart';
import 'features/authentication/presentation/screens/quran_screen.dart';
import 'features/authentication/presentation/screens/settings_screen.dart';
import 'features/authentication/presentation/screens/statistics_screen.dart';

class AppRoutes {
  //static const String initial = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String prayerTracking = '/prayer-tracking';
  static const String profile = '/profile';
  static const String statistics = '/statistics';
  static const String quran = '/quran';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
   // initial: (context) => const AuthWrapper(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    prayerTracking: (context) => const PrayerTrackingScreen(),
    profile: (context) => const ProfileScreen(),
    statistics: (context) => const StatisticsScreen(),
    quran: (context) => const QuranScreen(),
    settings: (context) => const SettingsScreen(),
  };
}