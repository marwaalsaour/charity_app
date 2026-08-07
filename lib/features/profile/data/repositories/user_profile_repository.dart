import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const _storageKey = 'user_profile';
  static const _userIdKey = 'current_user_id';

  Future<UserProfileModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    return UserProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
    if (profile.id != null) {
      await prefs.setString(_userIdKey, profile.id.toString());
    }
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_userIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final profile = await getProfile();
    if (profile?.id != null) {
      final id = profile!.id.toString();
      await prefs.setString(_userIdKey, id);
      return id;
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_userIdKey);
  }
}
