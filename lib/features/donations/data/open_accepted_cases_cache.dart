import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-wide cache of open accepted assistance cases for donor home.
///
/// Populated whenever any account successfully sees approved open cases
/// (beneficiary sync / open-accepted API). Donors then see them under
/// "Recent campaigns" even if a later API call returns empty.
class OpenAcceptedCasesCache {
  static const _key = 'open_accepted_cases_v1';

  static Future<void> upsertCases(List<Map<String, dynamic>> cases) async {
    if (cases.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = await _readRaw(prefs);
    final byId = <String, Map<String, dynamic>>{
      for (final item in existing)
        if (item['id'] != null) item['id'].toString(): item,
    };

    for (final item in cases) {
      final id = item['id'];
      if (id == null) continue;
      final key = id.toString();
      final prev = byId[key] ?? <String, dynamic>{};
      byId[key] = _mergePreservingNameConsent(prev, item);
    }

    final next = byId.values.toList()
      ..sort((a, b) {
        final ai = _toInt(a['id']) ?? 0;
        final bi = _toInt(b['id']) ?? 0;
        return bi.compareTo(ai);
      });

    await prefs.setString(_key, jsonEncode(next));
  }

  static Map<String, dynamic> _mergePreservingNameConsent(
    Map<String, dynamic> prev,
    Map<String, dynamic> incoming,
  ) {
    final merged = {...prev, ...incoming};
    final prevConsent = _isTruthy(prev['show_beneficiary_name']) ||
        _isTruthy(prev['showBeneficiaryName']);
    final incomingConsent = _isTruthy(incoming['show_beneficiary_name']) ||
        _isTruthy(incoming['showBeneficiaryName']);
    final showName = prevConsent || incomingConsent;
    if (showName) {
      merged['show_beneficiary_name'] = true;
      merged['showBeneficiaryName'] = true;
      merged['beneficiary_public_name'] =
          incoming['beneficiary_public_name'] ??
          incoming['beneficiary_name'] ??
          incoming['full_name'] ??
          prev['beneficiary_public_name'] ??
          prev['beneficiary_name'] ??
          prev['full_name'];
      merged['beneficiary_name'] =
          incoming['beneficiary_name'] ?? prev['beneficiary_name'];
      merged['beneficiaryName'] =
          incoming['beneficiaryName'] ?? prev['beneficiaryName'];
      merged['full_name'] = incoming['full_name'] ?? prev['full_name'];
    } else {
      merged['full_name'] = incoming['full_name'] ?? prev['full_name'];
      merged['beneficiary_public_name'] =
          incoming['beneficiary_public_name'] ??
          prev['beneficiary_public_name'];
    }
    return merged;
  }

  static bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> loadCases() async {
    final prefs = await SharedPreferences.getInstance();
    return _readRaw(prefs);
  }

  static Future<List<Map<String, dynamic>>> _readRaw(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return [];
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
