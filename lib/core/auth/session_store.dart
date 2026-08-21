import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/logic/home_cubit.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/logic/notifications_cubit.dart';
import '../../features/requests/logic/cubit/request_cubit.dart';

/// Clears per-account local data so a new login starts empty.
///
/// Theme and language are kept. Public case catalog is kept so donors still
/// see published cases; wallet, receipts, profile, and notifications are not.
class SessionStore {
  SessionStore._();

  static const _keepExact = {
    'theme_mode',
    'locale',
    'notifications_demo_cleared_v2',
    'open_accepted_cases_v1',
  };

  static const _keepPrefixes = ['flutter.'];

  static bool _shouldKeep(String key) {
    if (_keepExact.contains(key)) return true;
    for (final prefix in _keepPrefixes) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => !_shouldKeep(key)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    await NotificationRepository.instance.clearLocalSession();
  }

  static void resetBlocs(BuildContext context) {
    try {
      context.read<HomeCubit>().resetSession();
    } catch (_) {}
    try {
      context.read<NotificationsCubit>().resetSession();
    } catch (_) {}
    try {
      context.read<RequestCubit>().resetSession();
    } catch (_) {}
  }
}
