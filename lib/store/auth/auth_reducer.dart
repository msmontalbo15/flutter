import 'auth_state.dart';

class LoginSuccessAction {}
class LogoutAction {}

AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginSuccessAction) {
    return AuthState(isAuthenticated: true);
  }

  if (action is LogoutAction) {
    return AuthState(isAuthenticated: false);
  }

  return state;
}