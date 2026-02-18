import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../store/app_state.dart';
import '../screens/auth/login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, bool>(
      converter: (store) => store.state.auth.isAuthenticated,
      builder: (context, isAuthenticated) {
        if (!isAuthenticated) {
          return const LoginScreen();
        }
        return child;
      },
    );
  }
}