// lib/features/authentication/presentation/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Accès direct à l'écran d'accueil sans vérification d'authentification
    return HomeScreen();
  }
}