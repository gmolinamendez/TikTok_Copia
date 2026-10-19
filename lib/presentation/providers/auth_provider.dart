import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthProvider extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _subscription;

  User? user;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider() {
    user = _auth.currentUser;
    _subscription = _auth.authStateChanges().listen((newUser) {
      user = newUser;
      notifyListeners();
    });
  }

  Future<void> login( String email, String password ) =>
    _run(() => _auth.signInWithEmailAndPassword( email: email.trim(), password: password ));

  Future<void> register( String email, String password ) =>
    _run(() => _auth.createUserWithEmailAndPassword( email: email.trim(), password: password ));

  Future<void> logout() => _auth.signOut();

  Future<void> _run( Future<void> Function() action ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      // Si Authentication no está activado en la consola, Firebase manda "unknown" con este texto
      errorMessage = ( e.message ?? '' ).contains('CONFIGURATION_NOT_FOUND')
        ? _messageFor('operation-not-allowed')
        : _messageFor(e.code);
    }

    isLoading = false;
    notifyListeners();
  }

  String _messageFor( String code ) {
    switch (code) {
      case 'invalid-email': return 'El correo no es válido';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'Correo o contraseña incorrectos';
      case 'email-already-in-use': return 'Ese correo ya tiene una cuenta';
      case 'weak-password': return 'La contraseña debe tener al menos 6 caracteres';
      case 'operation-not-allowed': return 'El login con correo no está activado en Firebase';
      case 'network-request-failed': return 'Sin conexión a internet';
      default: return 'Ocurrió un error ($code)';
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

}
