// EDIT_TARGET: lib/screens/devices_screen.dart
// EDIT_PURPOSE: Database-backed classroom indicator, detail screen, and interactive controls
// EDIT_REASON: Allows toggling LED/Projector power and configuring AC state directly in InfluxDB

import 'package:flutter/material.dart';

import '../models/class_room_config.dart';
import '../models/influx_room_data.dart';
import '../services/influxdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.rooms,
    required this.influxDbService,
    required this.isActive,
    required this.refreshSignal,
  });

  final List<ClassRoomConfig> rooms;
  final InfluxDbService influxDbService;
  final bool isActive;
  final int refreshSignal;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String? _expandedRoom;
  bool _loadingIndicators = false;
  String? _loadError;
  Map<String, InfluxRoomData> _indicatorsByRoom = <String, InfluxRoomData>{};
  final Map<String, InfluxRoomData> _detailsByRoom = <String, InfluxRoomData>{};
  final Set<String> _loadingDetails = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _loadIndicators();
    }
  }

  @override
  void didUpdateWidget(covariant DevicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameActive = widget.isActive && !oldWidget.isActive;
    final refreshChanged = widget.refreshSignal != oldWidget.refreshSignal;
    if (becameActive || (widget.isActive && refreshChanged)) {
      _loadIndicators();
      if (_expandedRoom != null) {
        _loadRoomDetails(_expandedRoom!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Classrooms', style: AppTextStyles.sectionTitle),
            ),
            if (_loadingIndicators)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(message: _loadError!),
        ],
        const SizedBox(height: 12),
        if (rooms.isEmpty)
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(child: Text('No classrooms found in InfluxDB.')),
              ],
            ),
          )
        else
          for (final room in rooms) ...[
            _ClassroomCard(
              room: room,
              data: _indicatorsByRoom[room.className],
              isExpanded: _expandedRoom == room.className,
              onTap: () => _toggleRoom(room.className),
            ),
            if (_expandedRoom == room.className) ...[
              const SizedBox(height: 8),
              _RoomDetailsCard(
                data: _detailsByRoom[room.className],
                isLoading: _loadingDetails.contains(room.className),
                onFieldChanged: _updateRoomField,
              ),
            ],
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _loadIndicators() async {
    setState(() {
      _loadingIndicators = true;
      _loadError = null;
    });

    try {
      final indicators = await widget.influxDbService.loadRoomIndicators();
      if (!mounted) {
        return;
      }
      setState(() => _indicatorsByRoom = indicators);
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingIndicators = false);
      }
    }
  }

  void _toggleRoom(String room) {
    setState(() {
      _expandedRoom = _expandedRoom == room ? null : room;
    });
    if (_expandedRoom == room && !_detailsByRoom.containsKey(room)) {
      _loadRoomDetails(room);
    }
  }

  Future<void> _loadRoomDetails(String room) async {
    setState(() => _loadingDetails.add(room));
    try {
      final details = await widget.influxDbService.loadRoomDetails(room);
      if (!mounted || details == null) {
        return;
      }
      setState(() => _detailsByRoom[room] = details);
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDetails.remove(room));
      }
    }
  }

  Future<void> _updateRoomField(
      String room, String field, dynamic value) async {
    setState(() {
      _loadingDetails.add(room);
    });
    try {
      await widget.influxDbService.writeRoomField(room, field, value);
      await _loadRoomDetails(room);
      await _loadIndicators();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $field: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDetails.remove(room));
      }
    }
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.room,
    required this.data,
    required this.isExpanded,
    required this.onTap,
  });

  final ClassRoomConfig room;
  final InfluxRoomData? data;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.displayName, style: AppTextStyles.cardTitle),
                Text('${room.className} - ${room.buildingName}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          _IndicatorIcon(
            tooltip: 'Human',
            icon: Icons.person,
            active: data?.human == true,
            activeColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          _IndicatorIcon(
            tooltip: 'Alert',
            icon: Icons.warning_amber_outlined,
            active: data?.hasAlert == true,
            activeColor: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _IndicatorIcon(
            tooltip: 'Active',
            icon: Icons.circle,
            active: data?.active == true,
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
        ],
      ),
    );
  }
}

class _IndicatorIcon extends StatelessWidget {
  const _IndicatorIcon({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.activeColor,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: active ? activeColor : AppColors.offline),
    );
  }
}

class _RoomDetailsCard extends StatelessWidget {
  const _RoomDetailsCard({
    required this.data,
    required this.isLoading,
    required this.onFieldChanged,
  });

  final InfluxRoomData? data;
  final bool isLoading;
  final Function(String room, String field, dynamic value) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppCard(
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading class data...'),
          ],
        ),
      );
    }

    if (data == null) {
      return const AppCard(child: Text('Tap again to load class data.'));
    }

    final roomData = data!;
    return AppCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricBadge(
            label: 'temp',
            value: roomData.valueLabel('temp'),
            hasAlert: roomData.hasAlertFor('temp'),
          ),
          _MetricBadge(
            label: 'Lux',
            value: roomData.valueLabel('lux'),
            hasAlert: roomData.hasAlertFor('lux'),
          ),
          _MetricBadge(
            label: 'presense',
            value: roomData.valueLabel('presense'),
            hasAlert: roomData.hasAlertFor('human'),
          ),
          _InteractiveBadge(
            label: 'LED',
            value: roomData.valueLabel('led'),
            icon: Icons.lightbulb,
            isActive: roomData.led == true,
            hasAlert: roomData.hasAlertFor('led'),
            onTap: () {
              final nextVal = roomData.led == true ? false : true;
              onFieldChanged(roomData.room, 'led', nextVal);
            },
          ),
          _InteractiveBadge(
            label: 'Projector',
            value: roomData.valueLabel('projector'),
            icon: Icons.videocam,
            isActive: roomData.projector == true,
            hasAlert: roomData.hasAlertFor('projector'),
            onTap: () {
              final nextVal = roomData.projector == true ? false : true;
              onFieldChanged(roomData.room, 'projector', nextVal);
            },
          ),
          _InteractiveBadge(
            label: 'AC',
            value: roomData.valueLabel('ac'),
            icon: Icons.ac_unit,
            isActive: roomData.acPower == true,
            hasAlert: roomData.hasAlertFor('ac'),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return _AcControlDialog(
                    roomData: roomData,
                    onSave: onFieldChanged,
                  );
                },
              );
            },
          ),
          AppBadge(
            label: roomData.active == true ? 'active' : 'inactive',
            type: roomData.active == true
                ? AppBadgeType.online
                : AppBadgeType.offline,
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.hasAlert,
  });

  final String label;
  final String value;
  final bool hasAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.caption)),
              _AlertIcon(active: hasAlert),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _InteractiveBadge extends StatelessWidget {
  const _InteractiveBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.isActive,
    required this.hasAlert,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final bool hasAlert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: AppTextStyles.caption)),
                _AlertIcon(active: hasAlert),
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Active alert' : 'No active alert',
      child: Icon(
        Icons.warning_amber_outlined,
        size: 16,
        color: active ? AppColors.warning : AppColors.offline,
      ),
    );
  }
}

class _AcControlDialog extends StatefulWidget {
  const _AcControlDialog({
    required this.roomData,
    required this.onSave,
  });

  final InfluxRoomData roomData;
  final Function(String room, String field, dynamic value) onSave;

  @override
  State<_AcControlDialog> createState() => _AcControlDialogState();
}

class _AcControlDialogState extends State<_AcControlDialog> {
  late bool _power;
  late int _temp;
  late int _fan;

  @override
  void initState() {
    super.initState();
    _power = widget.roomData.acPower ?? false;
    _temp = widget.roomData.acTemp ?? 24;
    if (_temp < 16) _temp = 16;
    if (_temp > 30) _temp = 30;

    _fan = widget.roomData.acFan ?? 0;
    if (_fan < 0 || (_fan > 5 && _fan != 99)) {
      _fan = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('AC Control - Class ${widget.roomData.room}'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: const Text('Power'),
                value: _power,
                activeThumbColor: AppColors.success,
                onChanged: (val) {
                  setState(() {
                    _power = val;
                  });
                },
              ),
              if (_power) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Temperature', style: AppTextStyles.bodyMedium),
                    Text(
                      '$_temp°C',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 16,
                  max: 30,
                  divisions: 14,
                  value: _temp.toDouble(),
                  label: '$_temp°C',
                  onChanged: (val) {
                    setState(() {
                      _temp = val.round();
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Fan Speed',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _fan == 99 ? 0 : _fan,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Auto')),
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                    DropdownMenuItem(value: 4, child: Text('Quiet/Silent')),
                    DropdownMenuItem(value: 5, child: Text('Turbo/Powerful')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _fan = val;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final pp = _power ? '01' : '00';
            final tt = _temp.toString().padLeft(2, '0');
            final ff = _fan.toString().padLeft(2, '0');
            const ss = '99';
            final acCode = '$pp$tt$ff$ss';
            widget.onSave(widget.roomData.room, 'ac', acCode);
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
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
          Expanded(child: Text(message, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}
