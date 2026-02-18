import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:redux/redux.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/blog/blog_list_screen.dart';

import 'store/store.dart';
import 'store/app_state.dart';
import 'store/auth/auth_reducer.dart';
import 'store/theme_notifier.dart';
import 'widgets/auth_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://agctxurydhpbjwraduhv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnY3R4dXJ5ZGhwYmp3cmFkdWh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwOTcxNjEsImV4cCI6MjA4NDY3MzE2MX0.uJeLWQA3QDfkqe-pWYNGpLRCQx0JEynMA-PGOEjnzAA',
  );

  final Store<AppState> store = createStore();

  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) store.dispatch(LoginSuccessAction());

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn)
      store.dispatch(LoginSuccessAction());
    if (data.event == AuthChangeEvent.signedOut) store.dispatch(LogoutAction());
  });

  runApp(StoreProvider<AppState>(store: store, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Blogify',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthGuard(child: BlogListScreen()),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/blogs': (context) => const AuthGuard(child: BlogListScreen()),
          },
        );
      },
    );
  }
}
