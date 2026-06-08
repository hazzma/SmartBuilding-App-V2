// EDIT_TARGET: lib/app.dart
// EDIT_PURPOSE: Root MaterialApp plus small private app-shell helpers
// EDIT_REASON: One-off structure widgets stay here so lib/widgets only contains reusable components

import 'package:flutter/material.dart';

import 'models/class_room_config.dart';
import 'screens/auth_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/influxdb_service.dart';
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
  _AuthGate({AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<void> _loadAuth;

  @override
  void initState() {
    super.initState();
    _loadAuth = widget.authService.load();
    widget.authService.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadAuth,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoading();
        }
        if (!widget.authService.isAuthenticated) {
          return AuthScreen(authService: widget.authService);
        }
        return _AppShell(authService: widget.authService);
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
  final InfluxDbService _influxDbService = InfluxDbService();
  int _homeRefreshSignal = 0;
  int _scheduleRefreshSignal = 0;
  int _classesRefreshSignal = 0;

  final List<ClassRoomConfig> _classrooms = <ClassRoomConfig>[];

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    try {
      final roomNames = await _influxDbService.loadRooms();
      final nextClassrooms = roomNames.map(_classroomFromRoomTag).toList();
      if (!mounted) {
        return;
      }

      setState(() {
        _classrooms
          ..clear()
          ..addAll(nextClassrooms);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('InfluxDB room load failed: $error')),
      );
    }
  }

  ClassRoomConfig _classroomFromRoomTag(String room) {
    final normalized = room.trim();
    return ClassRoomConfig(
      id: 'room-${normalized.toLowerCase()}',
      className: normalized,
      displayName: 'Class $normalized',
      buildingName: _buildingNameFromRoom(normalized),
      floorName: _floorNameFromRoom(normalized),
      enabledSensors: const ['temperature', 'lux', 'presence'],
      detectedSensors: const ['temperature', 'lux', 'presence'],
      enabledControls: const ['lamp', 'ac', 'projector'],
    );
  }

  String _buildingNameFromRoom(String room) {
    if (room.isEmpty) {
      return 'Building';
    }
    return 'Building ${room[0].toUpperCase()}';
  }

  String _floorNameFromRoom(String room) {
    if (room.length < 2) {
      return 'Floor 1';
    }
    final floor = int.tryParse(room[1]);
    return floor == null ? 'Floor 1' : 'Floor $floor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Smart Class'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDummyStatus,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            rooms: _classrooms,
            influxDbService: _influxDbService,
            refreshSignal: _homeRefreshSignal,
          ),
          ScheduleScreen(
            rooms: _classrooms,
            influxDbService: _influxDbService,
            refreshSignal: _scheduleRefreshSignal,
          ),
          DevicesScreen(
            rooms: _classrooms,
            influxDbService: _influxDbService,
            isActive: _currentIndex == 2,
            refreshSignal: _classesRefreshSignal,
          ),
          SettingsScreen(
            onSignOut: widget.authService.signOut,
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
            icon: Icon(Icons.meeting_room), label: 'Classes'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _homeRefreshSignal++;
      } else if (index == 1) {
        _scheduleRefreshSignal++;
      } else if (index == 2) {
        _classesRefreshSignal++;
      }
    });
  }

  void _refreshDummyStatus() {
    if (_currentIndex == 2) {
      _loadClassrooms();
    }
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
