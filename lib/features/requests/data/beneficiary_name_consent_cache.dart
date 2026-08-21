import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BeneficiaryNameConsent {
  const BeneficiaryNameConsent({
    required this.showName,
    required this.name,
  });

  final bool showName;
  final String name;
}

/// Remembers the name the beneficiary typed and whether they allowed
/// publishing it, because public APIs often omit those fields.
class BeneficiaryNameConsentCache {
  static const _key = 'beneficiary_name_consent_v1';
  static const _pendingKey = 'beneficiary_name_consent_pending_v1';

  static Future<void> save({
    required int requestId,
    required bool showName,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (requestId <= 0 || trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    map[requestId.toString()] = {
      'show_beneficiary_name': showName,
      'name': trimmed,
    };
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<void> savePending({
    required bool showName,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode({
        'show_beneficiary_name': showName,
        'name': trimmed,
        'at': DateTime.now().toIso8601String(),
      }),
    );
  }

  static Future<BeneficiaryNameConsent?> get(int requestId) async {
    if (requestId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    final raw = map[requestId.toString()];
    if (raw is! Map) return null;
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    return BeneficiaryNameConsent(
      showName: raw['show_beneficiary_name'] == true,
      name: name,
    );
  }

  static Future<BeneficiaryNameConsent?> peekPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final name = decoded['name']?.toString().trim() ?? '';
      if (name.isEmpty) return null;
      return BeneficiaryNameConsent(
        showName: decoded['show_beneficiary_name'] == true,
        name: name,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  static Future<BeneficiaryNameConsent?> consumePending({
    String? fullName,
  }) async {
    final pending = await peekPending();
    if (pending == null) return null;
    final submittedName = fullName?.trim();
    if (submittedName != null &&
        submittedName.isNotEmpty &&
        submittedName.toLowerCase() != pending.name.toLowerCase()) {
      return null;
    }
    await clearPending();
    return pending;
  }

  static Future<Map<String, dynamic>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): entry.value,
      };
    } catch (_) {
      return {};
    }
  }
}
