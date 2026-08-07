import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const _key = 'theme_mode';

  ThemeCubit({ThemeMode initialMode = ThemeMode.light})
    : super(ThemeState(initialMode));

  Future<void> toggle() async {
    final isDark = state.mode == ThemeMode.dark;
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(ThemeState(next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'light' : 'dark');
  }

  bool get isDark => state.mode == ThemeMode.dark;
}
