import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre les changements d'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email et mot de passe
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;
      if (user != null) {
        // Mettre à jour le displayName de l'utilisateur
        await user.updateDisplayName(name);

        // Créer un profil utilisateur dans Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          email: email,
          name: name,
          latitude: 0.0, // Valeurs par défaut
          longitude: 0.0, // À mettre à jour avec la géolocalisation
          timezone: 'UTC', // À mettre à jour avec le fuseau horaire détecté
          notificationSettings: {
            'enabled': true,
            'intensity': 'medium',
            'sound': 'default',
            'vibration': true,
          },
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return newUser;
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<UserModel?> signIn(String email, String password) async {
    try {

      // Persistance définie sur SESSION (par défaut) pour maintenir l'utilisateur connecté
      // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;
      if (user != null) {
        // Récupérer les données utilisateur de Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Méthode à ajouter dans la classe AuthService
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

}