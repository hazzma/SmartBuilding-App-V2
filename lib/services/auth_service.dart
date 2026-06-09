// EDIT_TARGET: lib/services/auth_service.dart
// EDIT_PURPOSE: Connects the app auth flow to Firebase Authentication with inlined state properties.
// EDIT_REASON: FSD Section 17 requires Firebase Auth for user identity only; removed AuthState model to simplify the codebase.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_options.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  FirebaseAuth? _auth;
  bool _isListeningToAuthChanges = false;
  String? _lastError;

  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.uid;
  String? get currentUserEmail => _currentUser?.email;

  String? get lastError => _lastError;

  Future<void> load() async {
    final isReady = await _ensureFirebaseAuthReady();
    if (!isReady) {
      return;
    }

    _applyFirebaseUser(_auth!.currentUser);
    _listenToAuthChanges();
  }

  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    if (!_isValidEmail(email) || password.isEmpty) {
      _lastError = 'Enter a valid email and password.';
      return false;
    }

    if (!await _ensureFirebaseAuthReady()) {
      return false;
    }
    _listenToAuthChanges();

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _applyFirebaseUser(credential.user);
      notifyListeners();
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

  Future<bool> _ensureFirebaseAuthReady() async {
    if (_auth != null) {
      return true;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
      }
      _auth = FirebaseAuth.instance;
      _lastError = null;
      return true;
    } on UnsupportedError catch (error) {
      _lastError =
          'Firebase Auth is not configured for this platform. Run the app on Android or configure Firebase for this platform.';
      debugPrint('Firebase platform configuration error: $error');
      return false;
    } on FirebaseException catch (error) {
      _lastError =
          'Firebase initialization failed (${error.code}). Check the Firebase project configuration.';
      debugPrint('Firebase initialization error: ${error.code}: $error');
      return false;
    } on TimeoutException catch (error) {
      _lastError =
          'Firebase initialization timed out. Check the internet connection and Firebase configuration.';
      debugPrint('Firebase initialization timeout: $error');
      return false;
    } catch (error) {
      _lastError =
          'Firebase initialization failed. Check the internet connection and Firebase configuration.';
      debugPrint('Firebase initialization error: $error');
      return false;
    }
  }

  void _listenToAuthChanges() {
    if (_isListeningToAuthChanges || _auth == null) {
      return;
    }

    _isListeningToAuthChanges = true;
    _auth!.authStateChanges().listen((User? user) {
      _applyFirebaseUser(user);
      notifyListeners();
    });
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
