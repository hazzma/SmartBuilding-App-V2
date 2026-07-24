import 'package:flutter/material.dart';

import 'screens/devices_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'state/smart_building_controller.dart';
import 'theme/app_theme.dart';

// EDIT_TARGET: smart_building_app.dart
// EDIT_PURPOSE: Membuat MaterialApp dan shell navigasi utama Smart Building.
// EDIT_REASON: FSD update meminta main navigation disederhanakan menjadi Home, Devices, Settings.
class SmartBuildingApp extends StatefulWidget {
  const SmartBuildingApp({super.key});

  @override
  State<SmartBuildingApp> createState() => _SmartBuildingAppState();
}

class _SmartBuildingAppState extends State<SmartBuildingApp> {
  late final SmartBuildingController controller;

  @override
  void initState() {
    super.initState();
    controller = SmartBuildingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBuild V2',
      theme: AppTheme.light(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _AppShell(controller: controller),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: controller),
      DevicesScreen(controller: controller),
      SettingsScreen(controller: controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBuild V2'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                controller.isConnected ? 'MQTT Connected' : 'MQTT Offline',
                style: TextStyle(
                  color: controller.isConnected
                      ? AppColors.success
                      : AppColors.offline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: screens[controller.currentTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.currentTab,
        onDestinationSelected: controller.changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
