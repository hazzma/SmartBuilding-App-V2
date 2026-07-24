import 'master_state.dart';

// EDIT_TARGET: master_registry_item.dart
// EDIT_PURPOSE: Menyimpan ringkasan master untuk list dan status stale.
// EDIT_REASON: FSD meminta registry dari wildcard state dan stale rule 3 interval.
class MasterRegistryItem {
  const MasterRegistryItem({
    required this.state,
    required this.lastSeen,
    required this.staleAfter,
  });

  final MasterState state;
  final DateTime lastSeen;
  final Duration staleAfter;

  bool isStale(DateTime now) => now.difference(lastSeen) > staleAfter;
}
