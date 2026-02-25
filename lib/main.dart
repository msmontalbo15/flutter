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
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
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
  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Accent (same in both modes)
    const accent    = Color(0xFF646CFF);
    const accentDim = Color(0xFF4F56CC);

    // Dark palette
    const dkBgBase        = Color(0xFF020617);
    const dkBgSurface     = Color(0xFF0F172A);
    const dkBgSurfaceHigh = Color(0xFF1E293B);
    const dkBgSurfaceLow  = Color(0xFF0D1526);
    final dkInputFill     = const Color(0xFF0F172A).withOpacity(0.80);
    final dkInputBorder   = Colors.white.withOpacity(0.10);
    const dkText          = Color(0xFFE2E8F0);
    const dkTextSub       = Color(0xFF94A3B8);
    final dkOutline       = Colors.white.withOpacity(0.10);

    // Shadow colours
    final shadowColor = isDark
        ? const Color(0xFF646CFF).withOpacity(0.18)
        : Colors.black.withOpacity(0.10);
    final shadowColorDeep = isDark
        ? const Color(0xFF646CFF).withOpacity(0.30)
        : Colors.black.withOpacity(0.18);

    // Build colour scheme
    final ColorScheme colorScheme;
    if (isDark) {
      colorScheme = ColorScheme(
        brightness: Brightness.dark,
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF1E1F5E),
        onPrimaryContainer: const Color(0xFFC7C8FF),
        secondary: const Color(0xFF818CF8),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF1E1F4A),
        onSecondaryContainer: const Color(0xFFBEBFFF),
        tertiary: const Color(0xFF38BDF8),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFF0C2340),
        onTertiaryContainer: const Color(0xFFBAE6FD),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: const Color(0xFF3B1111),
        onErrorContainer: const Color(0xFFFCA5A5),
        surface: dkBgSurface,
        onSurface: dkText,
        surfaceContainerLow: dkBgSurfaceLow,
        surfaceContainerHighest: dkBgSurfaceHigh,
        onSurfaceVariant: dkTextSub,
        outline: dkOutline,
        outlineVariant: Colors.white.withOpacity(0.06),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: dkText,
        onInverseSurface: dkBgSurface,
        inversePrimary: accent,
        surfaceTint: accent,
      );
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? dkBgBase : colorScheme.surface,

      // AppBar — shadow added
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? dkBgSurface : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowColor,
        foregroundColor: isDark ? dkText : colorScheme.onSurface,
        elevation: 2,
        scrolledUnderElevation: 4,
        titleTextStyle: TextStyle(
          color: isDark ? dkText : colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Cards — shadow added
      cardTheme: CardThemeData(
        color: isDark ? dkBgSurface : colorScheme.surface,
        surfaceTintColor: isDark ? Colors.transparent : colorScheme.surfaceTint,
        elevation: isDark ? 0 : 2,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? dkOutline : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? dkInputFill : colorScheme.surfaceContainerLowest,
        hintStyle: TextStyle(
          color: (isDark ? dkTextSub : colorScheme.onSurfaceVariant).withOpacity(0.6),
        ),
        labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? dkInputBorder : colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),

      // Filled button — shadow added
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.12);
            }
            return accent;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.10)),
          shadowColor: WidgetStateProperty.all(shadowColorDeep),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 6.0;
            if (states.contains(WidgetState.pressed)) return 2.0;
            return 3.0;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      ),

      // Elevated button — shadow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentDim,
          foregroundColor: Colors.white,
          shadowColor: shadowColorDeep,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: isDark ? dkInputBorder : colorScheme.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // FAB — prominent shadow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        highlightElevation: 10,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? dkOutline : colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icons
      iconTheme: IconThemeData(
        color: isDark ? dkTextSub : colorScheme.onSurfaceVariant,
        size: 22,
      ),
      primaryIconTheme: IconThemeData(color: colorScheme.primary),

      // Text — dark only; light uses Material 3 defaults
      textTheme: isDark
          ? TextTheme(
              displayLarge:   TextStyle(color: dkText,    fontWeight: FontWeight.w700),
              displayMedium:  TextStyle(color: dkText,    fontWeight: FontWeight.w700),
              displaySmall:   TextStyle(color: dkText,    fontWeight: FontWeight.w700),
              headlineLarge:  TextStyle(color: dkText,    fontWeight: FontWeight.w700),
              headlineMedium: TextStyle(color: dkText,    fontWeight: FontWeight.w600),
              headlineSmall:  TextStyle(color: dkText,    fontWeight: FontWeight.w600),
              titleLarge:     TextStyle(color: dkText,    fontWeight: FontWeight.w600),
              titleMedium:    TextStyle(color: dkText,    fontWeight: FontWeight.w600),
              titleSmall:     TextStyle(color: dkText,    fontWeight: FontWeight.w500),
              bodyLarge:      TextStyle(color: dkText),
              bodyMedium:     TextStyle(color: dkText),
              bodySmall:      TextStyle(color: dkTextSub),
              labelLarge:     TextStyle(color: dkText,    fontWeight: FontWeight.w500),
              labelMedium:    TextStyle(color: dkTextSub),
              labelSmall:     TextStyle(color: dkTextSub),
            )
          : null,

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? dkBgSurfaceHigh : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: isDark ? dkText : colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Dialog — shadow added
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? dkBgSurface : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowColorDeep,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? dkOutline : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),

      // Bottom sheet — shadow
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? dkBgSurface : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowColorDeep,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? dkBgSurfaceHigh : colorScheme.surfaceContainerHighest,
        selectedColor: isDark ? const Color(0xFF1E1F5E) : colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: isDark ? dkText : colorScheme.onSurface),
        side: BorderSide(color: isDark ? dkOutline : colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

}
