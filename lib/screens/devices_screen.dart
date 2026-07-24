// EDIT_TARGET: lib/screens/devices_screen.dart
// EDIT_PURPOSE: Real-time classroom indicators, detail drawer, and interactive controls
// EDIT_REASON: Allows toggling LED/Projector power and configuring AC state directly via MQTT
import 'package:flutter/material.dart';

import '../models/class_room_config.dart';
import '../models/room_data.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.rooms,
    required this.mqttService,
    required this.isActive,
    required this.refreshSignal,
    required this.focusedRoom,
    required this.focusSignal,
  });

  final List<ClassRoomConfig> rooms;
  final MqttService mqttService;
  final bool isActive;
  final int refreshSignal;
  final String? focusedRoom;
  final int focusSignal;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String? _expandedRoom;
  final Set<String> _expandedBuildings = <String>{};
  final Set<String> _expandedFloors = <String>{};
  bool _loadingIndicators = false;
  String? _loadError;
  Map<String, RoomData> _indicatorsByRoom = <String, RoomData>{};
  final Map<String, RoomData> _detailsByRoom = <String, RoomData>{};
  final Set<String> _loadingDetails = <String>{};

  @override
  void initState() {
    super.initState();
    widget.mqttService.addListener(_onMqttUpdated);
    if (widget.isActive) {
      _loadIndicators();
    }
  }

  @override
  void dispose() {
    widget.mqttService.removeListener(_onMqttUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DevicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mqttService != oldWidget.mqttService) {
      oldWidget.mqttService.removeListener(_onMqttUpdated);
      widget.mqttService.addListener(_onMqttUpdated);
    }
    final becameActive = widget.isActive && !oldWidget.isActive;
    final refreshChanged = widget.refreshSignal != oldWidget.refreshSignal;
    if (becameActive || (widget.isActive && refreshChanged)) {
      _loadIndicators();
      if (_expandedRoom != null) {
        _loadRoomDetails(_expandedRoom!);
      }
    }
    if (widget.isActive &&
        widget.focusSignal != oldWidget.focusSignal &&
        widget.focusedRoom != null) {
      _focusRoom(widget.focusedRoom!);
    }
  }

  void _onMqttUpdated() {
    debugPrint('DevicesScreen: _onMqttUpdated triggered. isActive: ${widget.isActive}');
    if (mounted && widget.isActive) {
      _loadIndicators();
      debugPrint('DevicesScreen: Indicators loaded. RoomData count: ${_indicatorsByRoom.length}');
      if (_expandedRoom != null) {
        _loadRoomDetails(_expandedRoom!);
        final details = _detailsByRoom[_expandedRoom];
        debugPrint('DevicesScreen: Expanded details for $_expandedRoom: lux=${details?.lux}, temp=${details?.temp}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms;
    final groupedRooms = _groupRooms(rooms);

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
          for (final buildingEntry in groupedRooms.entries) ...[
            _HierarchyHeader(
              icon: Icons.apartment_outlined,
              label: buildingEntry.key,
              count: buildingEntry.value.values
                  .fold<int>(0, (count, rooms) => count + rooms.length),
              isExpanded: _expandedBuildings.contains(buildingEntry.key),
              onTap: () => _toggleBuilding(buildingEntry.key),
            ),
            if (_expandedBuildings.contains(buildingEntry.key))
              for (final floorEntry in buildingEntry.value.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: _HierarchyHeader(
                    icon: Icons.layers_outlined,
                    label: floorEntry.key,
                    count: floorEntry.value.length,
                    isExpanded: _expandedFloors.contains(
                      _floorKey(buildingEntry.key, floorEntry.key),
                    ),
                    onTap: () => _toggleFloor(
                      buildingEntry.key,
                      floorEntry.key,
                    ),
                  ),
                ),
                if (_expandedFloors.contains(
                  _floorKey(buildingEntry.key, floorEntry.key),
                ))
                  for (final room in floorEntry.value) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 8),
                      child: _ClassroomCard(
                        room: room,
                        data: _indicatorsByRoom[room.className],
                        isExpanded: _expandedRoom == room.className,
                        onTap: () => _toggleRoom(room.className),
                      ),
                    ),
                    if (_expandedRoom == room.className)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: _RoomDetailsCard(
                          data: _detailsByRoom[room.className],
                          isLoading: _loadingDetails.contains(room.className),
                          onFieldChanged: _updateRoomField,
                        ),
                      ),
                  ],
              ],
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Map<String, Map<String, List<ClassRoomConfig>>> _groupRooms(
    List<ClassRoomConfig> rooms,
  ) {
    final grouped = <String, Map<String, List<ClassRoomConfig>>>{};
    final sortedRooms = [...rooms]
      ..sort((a, b) => a.className.compareTo(b.className));
    for (final room in sortedRooms) {
      grouped
          .putIfAbsent(
            room.buildingName,
            () => <String, List<ClassRoomConfig>>{},
          )
          .putIfAbsent(room.floorName, () => <ClassRoomConfig>[])
          .add(room);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String _floorKey(String building, String floor) => '$building::$floor';

  void _toggleBuilding(String building) {
    setState(() {
      if (!_expandedBuildings.add(building)) {
        _expandedBuildings.remove(building);
      }
    });
  }

  void _toggleFloor(String building, String floor) {
    final key = _floorKey(building, floor);
    setState(() {
      if (!_expandedFloors.add(key)) {
        _expandedFloors.remove(key);
      }
    });
  }

  void _focusRoom(String roomName) {
    ClassRoomConfig? target;
    for (final room in widget.rooms) {
      if (room.className == roomName) {
        target = room;
        break;
      }
    }
    if (target == null) {
      return;
    }

    setState(() {
      _expandedBuildings.add(target!.buildingName);
      _expandedFloors.add(_floorKey(target.buildingName, target.floorName));
      _expandedRoom = target.className;
    });
    _loadRoomDetails(target.className);
  }

  Future<void> _loadIndicators() async {
    setState(() {
      _indicatorsByRoom = widget.mqttService.roomIndicators;
    });
  }

  void _toggleRoom(String room) {
    setState(() {
      _expandedRoom = _expandedRoom == room ? null : room;
    });
    if (_expandedRoom == room && !_detailsByRoom.containsKey(room)) {
      _loadRoomDetails(room);
    }
  }

  void _loadRoomDetails(String room) {
    final details = widget.mqttService.getRoomDetails(room);
    if (details != null) {
      setState(() => _detailsByRoom[room] = details);
    }
  }

  void _updateRoomField(String room, String field, dynamic value) {
    widget.mqttService.publishControl(room, field, value);
    _loadRoomDetails(room);
    _loadIndicators();
  }
}

class _HierarchyHeader extends StatelessWidget {
  const _HierarchyHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.cardTitle)),
          Text('$count', style: AppTextStyles.caption),
          const SizedBox(width: 8),
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
        ],
      ),
    );
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
  final RoomData? data;
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

  final RoomData? data;
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

  final RoomData roomData;
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
