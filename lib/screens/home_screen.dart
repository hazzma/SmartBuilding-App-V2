// EDIT_TARGET: lib/screens/home_screen.dart
// EDIT_PURPOSE: Campus overview, global lighting controls, ongoing classes and active alerts
// EDIT_REASON: Home should focus on global status instead of classroom-specific detail panels

import 'dart:async';

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
  InfluxHomeSummary? _summary;
  List<InfluxRoomData> _allRoomsData = [];
  List<InfluxOngoingClass> _ongoingClasses = [];
  bool _isLoading = false;
  bool _isUpdatingCampusLights = false;
  String? _loadError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadHomeData(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
          isUpdating: _isUpdatingCampusLights,
          onTurnOn: () => _setCampusLights(true),
          onTurnOff: () => _setCampusLights(false),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Active Alerts'),
        const SizedBox(height: 8),
        _ActiveAlertsList(roomsData: _allRoomsData),
        const SizedBox(height: 20),
        const _SectionTitle('Ongoing Classes'),
        const SizedBox(height: 8),
        _OngoingClassesList(ongoingClasses: _ongoingClasses),
      ],
    );
  }

  Future<void> _loadHomeData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        widget.influxDbService.loadRooms(),
        widget.influxDbService.loadRoomIndicators(),
        widget.influxDbService.loadOngoingClasses(),
      ]);
      final rooms = results[0] as List<String>;
      final indicators = results[1] as Map<String, InfluxRoomData>;
      final ongoingClasses = results[2] as List<InfluxOngoingClass>;
      final summary = InfluxHomeSummary(
        totalClasses: rooms.length,
        activeClasses: ongoingClasses.length,
        alertCount: indicators.values.where((room) => room.hasAlert).length,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _allRoomsData = indicators.values.toList();
        _ongoingClasses = ongoingClasses;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setCampusLights(bool turnOn) async {
    if (_isUpdatingCampusLights) {
      return;
    }

    setState(() => _isUpdatingCampusLights = true);
    try {
      await widget.influxDbService.writeCampusLights(turnOn);
      if (!mounted) {
        return;
      }
      setState(() => _campusLightsOn = turnOn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            turnOn
                ? 'All campus lights turned on.'
                : 'All campus lights turned off.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update campus lights: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingCampusLights = false);
      }
    }
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
  const _OngoingClassesList({required this.ongoingClasses});

  final List<InfluxOngoingClass> ongoingClasses;

  @override
  Widget build(BuildContext context) {
    if (ongoingClasses.isEmpty) {
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
      children: ongoingClasses.map((ongoingClass) {
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
                      'Classroom ${ongoingClass.room}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${ongoingClass.session.label} '
                      '(${ongoingClass.session.timeRange})',
                      style: AppTextStyles.caption,
                    ),
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
        final alerts = roomData.alertLabels;
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert in Classroom ${roomData.room}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerts.isEmpty ? 'General alert' : alerts.join(', '),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
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
    required this.isUpdating,
    required this.onTurnOn,
    required this.onTurnOff,
  });

  final bool? campusLightsOn;
  final bool isUpdating;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

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
                  _ when isUpdating => 'updating',
                  true => 'all on',
                  false => 'all off',
                  null => 'not set',
                },
                type: switch (campusLightsOn) {
                  _ when isUpdating => AppBadgeType.warning,
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
                onPressed: isUpdating ? null : onTurnOn,
              );
              final turnOffButton = _CampusLightButton(
                label: 'All Lights Off',
                icon: Icons.lightbulb_outline,
                color: AppColors.error,
                onPressed: isUpdating ? null : onTurnOff,
              );
              if (stackButtons) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    turnOnButton,
                    const SizedBox(height: 10),
                    turnOffButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: turnOnButton),
                  const SizedBox(width: 12),
                  Expanded(child: turnOffButton),
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
  final VoidCallback? onPressed;

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
