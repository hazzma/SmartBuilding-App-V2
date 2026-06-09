// EDIT_TARGET: lib/services/auth_service.dart
// EDIT_PURPOSE: Connects the app auth flow to Firebase Authentication with inlined state properties.
// EDIT_REASON: FSD Section 17 requires Firebase Auth for user identity only; removed AuthState model to simplify the codebase.

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  FirebaseAuth? _auth;
  String? _lastError;

  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.uid;
  String? get currentUserEmail => _currentUser?.email;


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
    _currentUser = user;
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
