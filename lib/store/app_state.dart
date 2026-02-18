import 'auth/auth_state.dart';

class AppState {
  final AuthState auth;

  AppState({required this.auth});

  factory AppState.initial() =>
      AppState(auth: AuthState.initial());
}