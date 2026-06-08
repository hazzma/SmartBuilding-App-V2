// EDIT_TARGET: auth_state.dart
// EDIT_PURPOSE: Defines the lightweight authenticated user state
// EDIT_REASON: Accounts are provisioned manually, so only sign-in state is needed

class AuthState {
  const AuthState({
    this.currentUserId,
    this.currentUserEmail,
    this.isAuthenticated = false,
  });

  final String? currentUserId;
  final String? currentUserEmail;
  final bool isAuthenticated;

  AuthState copyWith({
    String? currentUserId,
    String? currentUserEmail,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentUserId': currentUserId,
      'currentUserEmail': currentUserEmail,
      'isAuthenticated': isAuthenticated,
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      currentUserId: json['currentUserId'] as String?,
      currentUserEmail: json['currentUserEmail'] as String?,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
    );
  }
}
