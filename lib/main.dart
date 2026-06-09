// EDIT_TARGET: lib/main.dart
// EDIT_PURPOSE: Main entry point of the Flutter application
// EDIT_REASON: Starts the Smart Building App from a single Flutter entry point

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SmartBuildingApp());
}
