// EDIT_TARGET: lib/screens/home_screen.dart
// EDIT_PURPOSE: Campus overview, global lighting controls, and active alerts list
// EDIT_REASON: Connects the campus-wide status blocks and buttons to real-time MQTT events
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/class_room_config.dart';
import '../models/room_data.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.rooms = const [],
    required this.mqttService,
    required this.refreshSignal,
    required this.onAlertSelected,
  });

  final List<ClassRoomConfig> rooms;
  final MqttService mqttService;
  final int refreshSignal;
  final ValueChanged<String> onAlertSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _campusLightsOn;
  HomeSummary? _summary;
  List<RoomData> _allRoomsData = [];
  bool _isLoading = false;
  bool _isUpdatingCampusLights = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    widget.mqttService.addListener(_onMqttUpdated);
    _loadHomeData();
  }

  @override
  void dispose() {
    widget.mqttService.removeListener(_onMqttUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mqttService != oldWidget.mqttService) {
      oldWidget.mqttService.removeListener(_onMqttUpdated);
      widget.mqttService.addListener(_onMqttUpdated);
    }
    _loadHomeData(showLoading: false);
  }

  void _onMqttUpdated() {
    debugPrint('HomeScreen: _onMqttUpdated triggered.');
    if (mounted) {
      _loadHomeData(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms;
    final summary = _summary ??
        HomeSummary(
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
        _ActiveAlertsList(
          roomsData: _allRoomsData,
          onAlertSelected: widget.onAlertSelected,
        ),
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
      final summary = await widget.mqttService.loadHomeSummary();
      final indicators = widget.mqttService.roomIndicators;
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _allRoomsData = indicators.values.toList();
        _loadError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setCampusLights(bool turnOn) {
    if (_isUpdatingCampusLights) {
      return;
    }

    setState(() => _isUpdatingCampusLights = true);
    try {
      widget.mqttService.publishCampusLights(turnOn);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update campus lights: $error')),
      );
    } finally {
      setState(() => _isUpdatingCampusLights = false);
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

class _ActiveAlertsList extends StatelessWidget {
  const _ActiveAlertsList({
    required this.roomsData,
    required this.onAlertSelected,
  });

  final List<RoomData> roomsData;
  final ValueChanged<String> onAlertSelected;

  @override
  Widget build(BuildContext context) {
    final alertRooms = roomsData.where((r) => r.hasAlert).toList()
      ..sort((a, b) => a.room.compareTo(b.room));

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

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(
          Icons.warning_amber_outlined,
          color: AppColors.warning,
        ),
        title: Text(
          '${alertRooms.length} ${alertRooms.length == 1 ? 'class has' : 'classes have'} alerts',
          style: AppTextStyles.cardTitle,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          const Divider(height: 1),
          for (var index = 0; index < alertRooms.length; index++) ...[
            ListTile(
              leading: const Icon(
                Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
              title: Text('Class ${alertRooms[index].room} has alerts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onAlertSelected(alertRooms[index].room),
            ),
            if (index != alertRooms.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
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
