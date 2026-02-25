import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void setLight() => value = ThemeMode.light;
  void setDark() => value = ThemeMode.dark;
  void setSystem() => value = ThemeMode.system;

  void toggle() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDark => value == ThemeMode.dark;
}

// Global instance accessible from anywhere
final themeNotifier = ThemeNotifier();
