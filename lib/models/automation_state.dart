// EDIT_TARGET: automation_state.dart
// EDIT_PURPOSE: Defines automation room lifecycle status values.
// EDIT_REASON: FSD V2 requires status reporting for schedule automation and presence safety.

enum AutomationRoomStatus {
  idle,
  preStarting,
  scheduledActive,
  waitingEmpty,
  shuttingDown,
  pausedPresenceUnavailable,
}
