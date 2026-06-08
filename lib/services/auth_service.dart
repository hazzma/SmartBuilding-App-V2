// EDIT_TARGET: lib/services/auth_service.dart
// EDIT_PURPOSE: Connects the app auth flow to Firebase Authentication.
// EDIT_REASON: FSD Section 17 requires Firebase Auth for user identity only.

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_state.dart';

class AuthService extends ChangeNotifier {
  AuthState _state = const AuthState();
  FirebaseAuth? _auth;
  String? _lastError;

  AuthState get state => _state;

  bool get isAuthenticated => _state.isAuthenticated;

  String? get lastError => _lastError;

  Future<void> load() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _applyFirebaseUser(_auth!.currentUser);
        _auth!.authStateChanges().listen((User? user) {
          _applyFirebaseUser(user);
          notifyListeners();
        });
      } else {
        _lastError = 'Firebase is not initialized.';
        debugPrint(
          'AuthService: Firebase not initialized. Auth features will be disabled.',
        );
      }
    } catch (e) {
      _lastError = 'Unable to load authentication.';
      debugPrint('AuthService load error: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    if (!_isValidEmail(email) || password.isEmpty) {
      _lastError = 'Enter a valid email and password.';
      return false;
    }

    if (_auth == null) {
      _lastError = 'Firebase Auth is not ready.';
      return false;
    }

    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _messageForAuthException(e);
      debugPrint('Firebase SignIn Error: ${e.code}');
      return false;
    } catch (e) {
      _lastError = 'Unable to sign in right now.';
      debugPrint('Firebase SignIn Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _lastError = null;
    if (_auth != null) {
      try {
        await _auth!.signOut();
        _applyFirebaseUser(null);
        notifyListeners();
      } on FirebaseAuthException catch (e) {
        _lastError = _messageForAuthException(e);
        debugPrint('Firebase SignOut Error: ${e.code}');
      } catch (e) {
        _lastError = 'Unable to sign out right now.';
        debugPrint('Firebase SignOut Error: $e');
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  void _applyFirebaseUser(User? user) {
    if (user == null) {
      _state = const AuthState(isAuthenticated: false);
      return;
    }
    _state = AuthState(
      currentUserId: user.uid,
      currentUserEmail: user.email,
      isAuthenticated: true,
    );
  }

  String _messageForAuthException(FirebaseAuthException exception) {
    return switch (exception.code) {
      'invalid-email' => 'Enter a valid email address.',
      'operation-not-allowed' =>
        'Email/password login is not enabled in Firebase Console.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Email or password is incorrect.',
      'network-request-failed' => 'Check your internet connection.',
      _ => exception.message ?? 'Authentication failed.',
    };
  }
}
