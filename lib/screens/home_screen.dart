// EDIT_TARGET: lib/screens/home_screen.dart
// EDIT_PURPOSE: Campus overview, global lighting controls, ongoing classes and active alerts
// EDIT_REASON: Home should focus on global status instead of classroom-specific detail panels

import 'package:flutter/material.dart';

import '../models/class_room_config.dart';
import '../models/influx_room_data.dart';
import '../services/influxdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.rooms = const [],
    required this.influxDbService,
    required this.refreshSignal,
  });

  final List<ClassRoomConfig> rooms;
  final InfluxDbService influxDbService;
  final int refreshSignal;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _campusLightsOn;
  bool _lightsMatchSchedule = false;
  InfluxHomeSummary? _summary;
  List<InfluxRoomData> _allRoomsData = [];
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms;
    final summary = _summary ??
        InfluxHomeSummary(
          totalClasses: rooms.length,
          activeClasses: 0,
          alertCount: 0,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        if (_loadError != null) ...[
          _ErrorCard(message: _loadError!),
          const SizedBox(height: 12),
        ],
        _HomeSummaryRow(
          totalClasses: summary.totalClasses,
          activeClasses: summary.activeClasses,
          alertCount: summary.alertCount,
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Controls'),
        const SizedBox(height: 8),
        _CampusLightingControls(
          campusLightsOn: _campusLightsOn,
          lightsMatchSchedule: _lightsMatchSchedule,
          onTurnOn: () => _setCampusLights(true),
          onTurnOff: () => _setCampusLights(false),
          onMatchSchedule: _matchLightsToSchedule,
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Active Alerts'),
        const SizedBox(height: 8),
        _ActiveAlertsList(roomsData: _allRoomsData),
        const SizedBox(height: 20),
        const _SectionTitle('Ongoing Classes'),
        const SizedBox(height: 8),
        _OngoingClassesList(roomsData: _allRoomsData),
      ],
    );
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final summary = await widget.influxDbService.loadHomeSummary();
      final indicators = await widget.influxDbService.loadRoomIndicators();
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _allRoomsData = indicators.values.toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setCampusLights(bool turnOn) {
    setState(() {
      _campusLightsOn = turnOn;
      _lightsMatchSchedule = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          turnOn
              ? 'Dummy action: all campus lights turned on.'
              : 'Dummy action: all campus lights turned off.',
        ),
      ),
    );
  }

  void _matchLightsToSchedule() {
    setState(() {
      _campusLightsOn = null;
      _lightsMatchSchedule = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dummy action: all lights now match schedule.'),
      ),
    );
  }
}

class _HomeSummaryRow extends StatelessWidget {
  const _HomeSummaryRow({
    required this.totalClasses,
    required this.activeClasses,
    required this.alertCount,
  });

  final int totalClasses;
  final int activeClasses;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryBlock(
            label: 'Total Classes',
            value: totalClasses.toString(),
            icon: Icons.meeting_room_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryBlock(
            label: 'Active Classes',
            value: activeClasses.toString(),
            icon: Icons.lightbulb_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryBlock(
            label: 'Alerts',
            value: alertCount.toString(),
            icon: Icons.warning_amber_outlined,
            color: alertCount == 0 ? AppColors.offline : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(value, style: AppTextStyles.displayTitle),
            Text(label, style: AppTextStyles.caption, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _OngoingClassesList extends StatelessWidget {
  const _OngoingClassesList({required this.roomsData});

  final List<InfluxRoomData> roomsData;

  @override
  Widget build(BuildContext context) {
    final activeRooms = roomsData.where((r) => r.isActive).toList();

    if (activeRooms.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, color: AppColors.offline),
            SizedBox(width: 12),
            Expanded(child: Text('No ongoing classes.')),
          ],
        ),
      );
    }

    return Column(
      children: activeRooms.map((roomData) {
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classroom ${roomData.room}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text('Class is currently in progress', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const AppBadge(
                label: 'active',
                type: AppBadgeType.online,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveAlertsList extends StatelessWidget {
  const _ActiveAlertsList({required this.roomsData});

  final List<InfluxRoomData> roomsData;

  @override
  Widget build(BuildContext context) {
    final alertRooms = roomsData.where((r) => r.hasAlert).toList();

    if (alertRooms.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 12),
            Expanded(child: Text('No active classroom alerts.')),
          ],
        ),
      );
    }

    return Column(
      children: alertRooms.map((roomData) {
        final alerts = _decodeAlertCode(roomData.alert);
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert in Classroom ${roomData.room}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerts.join(', '),
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _decodeAlertCode(dynamic alertValue) {
    if (alertValue == null) return [];
    if (alertValue == 0 || alertValue == false || alertValue == '0') return [];

    final alertStr = alertValue.toString().trim();
    if (alertStr == 'true' || (alertStr == '1' && alertStr.length == 1)) {
      return ['General Alert'];
    }

    final flags = [
      'Temperature error',
      'CO2 error',
      'Lux error',
      'Human error',
      'LED error',
      'Projector error',
      'AC error',
      'Presence outside schedule',
    ];

    final activeAlerts = <String>[];
    if (alertStr.length == 7) {
      for (var i = 0; i < 6; i++) {
        if (alertStr[i] == '1') {
          activeAlerts.add(flags[i]);
        }
      }
      if (alertStr[6] == '1') {
        activeAlerts.add(flags[7]);
      }
    } else {
      final padded = alertStr.padLeft(8, '0');
      for (var i = 0; i < padded.length && i < flags.length; i++) {
        if (padded[i] == '1') {
          activeAlerts.add(flags[i]);
        }
      }
    }
    return activeAlerts;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionTitle);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _CampusLightingControls extends StatelessWidget {
  const _CampusLightingControls({
    required this.campusLightsOn,
    required this.lightsMatchSchedule,
    required this.onTurnOn,
    required this.onTurnOff,
    required this.onMatchSchedule,
  });

  final bool? campusLightsOn;
  final bool lightsMatchSchedule;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;
  final VoidCallback onMatchSchedule;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Campus Lighting',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              AppBadge(
                label: switch (campusLightsOn) {
                  _ when lightsMatchSchedule => 'schedule',
                  true => 'all on',
                  false => 'all off',
                  null => 'not set',
                },
                type: switch (campusLightsOn) {
                  _ when lightsMatchSchedule => AppBadgeType.warning,
                  true => AppBadgeType.online,
                  false => AppBadgeType.error,
                  null => AppBadgeType.offline,
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 420;
              final turnOnButton = _CampusLightButton(
                label: 'All Lights On',
                icon: Icons.lightbulb,
                color: AppColors.success,
                onPressed: onTurnOn,
              );
              final turnOffButton = _CampusLightButton(
                label: 'All Lights Off',
                icon: Icons.lightbulb_outline,
                color: AppColors.error,
                onPressed: onTurnOff,
              );
              final scheduleButton = _CampusLightButton(
                label: 'All Lights Match Schedule',
                icon: Icons.event_available,
                color: AppColors.primary,
                onPressed: onMatchSchedule,
              );

              if (stackButtons) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    turnOnButton,
                    const SizedBox(height: 10),
                    turnOffButton,
                    const SizedBox(height: 10),
                    scheduleButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: turnOnButton),
                  const SizedBox(width: 12),
                  Expanded(child: turnOffButton),
                  const SizedBox(width: 12),
                  Expanded(child: scheduleButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CampusLightButton extends StatelessWidget {
  const _CampusLightButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
