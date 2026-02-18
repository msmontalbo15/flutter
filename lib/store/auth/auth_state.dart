class AuthState {
  final bool isAuthenticated;

  AuthState({required this.isAuthenticated});

  factory AuthState.initial() =>
      AuthState(isAuthenticated: false);
}