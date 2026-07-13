import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_role.dart';

class UserRoleCubit extends Cubit<UserRole?> {
  static const _key = 'user_role';

  UserRoleCubit() : super(null);

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = UserRole.fromString(prefs.getString(_key));
    if (saved != null) emit(saved);
  }

  Future<void> setRole(UserRole role) async {
    emit(role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role.name);
  }

  Future<void> clearRole() async {
    emit(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
