import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String _dniToEmail(String dni) {
    return '${dni.trim()}@iv.edu.pe';
  }

  Future<void> loginConDni({
    required String dni,
    required String password,
  }) async {
    final email = _dniToEmail(dni);

    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AppUser?> obtenerUsuarioActual() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _db.collection('usuarios').doc(user.uid).get();

    if (!doc.exists) {
      return null;
    }

    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> streamUsuarioActual() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _db.collection('usuarios').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }
}