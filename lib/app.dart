// EDIT_TARGET: lib/app.dart
// EDIT_PURPOSE: Root MaterialApp plus AppShell state container using MqttService
// EDIT_REASON: Connects the navigation shell and sub-screens to real-time MQTT events
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/mqtt_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/app_button.dart';

class SmartBuildingApp extends StatelessWidget {
  const SmartBuildingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Building App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({this.authService});

  final AuthService? authService;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthService? _authService;
  Future<void>? _loadAuth;

  @override
  void initState() {
    super.initState();
    final service = widget.authService ?? AuthService();
    _authService = service;
    _loadAuth = service.load();
    service.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    _authService?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleMqttChanged() {}

  void _handleAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadAuth = _loadAuth;
    final service = _authService;
    if (loadAuth == null || service == null) {
      return const AppLoading();
    }

    return FutureBuilder<void>(
      future: loadAuth,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoading();
        }
        if (!service.isAuthenticated) {
          return AuthScreen(authService: service);
        }
        return _AppShell(authService: service);
      },
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.authService});

  final AuthService authService;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  final MqttService _mqttService = MqttService();
  int _homeRefreshSignal = 0;
  int _scheduleRefreshSignal = 0;
  int _classesRefreshSignal = 0;
  int _classFocusSignal = 0;
  String? _focusedClassroom;

  @override
  void initState() {
    super.initState();
    _mqttService.addListener(_handleMqttChanged);
    _mqttService.connect();
  }

  @override
  void dispose() {
    _mqttService.removeListener(_handleMqttChanged);
    _mqttService.disconnect();
    super.dispose();
  }

  void _handleMqttChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final classroomsList = _mqttService.classrooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Smart Class'),
        actions: [
          IconButton(
            tooltip: 'Refresh / Reconnect',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMqttStatus,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            rooms: classroomsList,
            mqttService: _mqttService,
            refreshSignal: _homeRefreshSignal,
            onAlertSelected: _openClassroom,
          ),
          ScheduleScreen(
            rooms: classroomsList,
            mqttService: _mqttService,
            refreshSignal: _scheduleRefreshSignal,
          ),
          DevicesScreen(
            rooms: classroomsList,
            mqttService: _mqttService,
            isActive: _currentIndex == 2,
            refreshSignal: _classesRefreshSignal,
            focusedRoom: _focusedClassroom,
            focusSignal: _classFocusSignal,
          ),
          SettingsScreen(
            onSignOut: widget.authService.signOut,
            mqttService: _mqttService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room),
            label: 'Classes',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 2) {
        _focusedClassroom = null;
      }
      if (index == 0) {
        _homeRefreshSignal++;
      } else if (index == 1) {
        _scheduleRefreshSignal++;
      } else if (index == 2) {
        _classesRefreshSignal++;
      }
    });
  }

  void _openClassroom(String room) {
    setState(() {
      _currentIndex = 2;
      _focusedClassroom = room;
      _classFocusSignal++;
      _classesRefreshSignal++;
    });
  }

  void _refreshMqttStatus() {
    _mqttService.connect();
    setState(() {
      if (_currentIndex == 0) {
        _homeRefreshSignal++;
      } else if (_currentIndex == 1) {
        _scheduleRefreshSignal++;
      } else if (_currentIndex == 2) {
        _classesRefreshSignal++;
      }
    });
  }
}
