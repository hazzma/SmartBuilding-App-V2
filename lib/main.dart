// EDIT_TARGET: lib/main.dart
// EDIT_PURPOSE: Main entry point of the Flutter application
// EDIT_REASON: Starts the Smart Building App from a single Flutter entry point

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const SmartBuildingApp());
}
