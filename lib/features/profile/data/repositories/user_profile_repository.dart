import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const _storageKey = 'user_profile';

  Future<UserProfileModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    return UserProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
  }
}
