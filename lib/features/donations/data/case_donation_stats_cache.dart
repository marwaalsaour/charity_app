import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CaseDonationStats {
  const CaseDonationStats({
    required this.donorsCount,
    required this.raised,
  });

  final int donorsCount;
  final double raised;
}

/// Local per-case donation stats so UI updates immediately after a successful
/// donate, even when Azure open-accepted payloads omit donors_count.
class CaseDonationStatsCache {
  static const _key = 'case_donation_stats_v1';

  static Future<void> recordDonation({
    required int requestId,
    required double amountUsd,
  }) async {
    if (requestId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    final current = map[requestId.toString()];
    final donors = (current?.donorsCount ?? 0) + 1;
    final raised = (current?.raised ?? 0) + amountUsd;
    map[requestId.toString()] = CaseDonationStats(
      donorsCount: donors,
      raised: raised,
    );
    await _write(prefs, map);
  }

  static Future<void> mergeFromServer({
    required int requestId,
    required int donorsCount,
    required double raised,
  }) async {
    if (requestId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    final current = map[requestId.toString()];
    map[requestId.toString()] = CaseDonationStats(
      donorsCount: donorsCount > (current?.donorsCount ?? 0)
          ? donorsCount
          : (current?.donorsCount ?? 0),
      raised: raised > (current?.raised ?? 0)
          ? raised
          : (current?.raised ?? 0),
    );
    await _write(prefs, map);
  }

  static Future<CaseDonationStats?> get(int requestId) async {
    if (requestId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    return map[requestId.toString()];
  }

  static Future<Map<String, CaseDonationStats>> _read(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, CaseDonationStats>{};
      decoded.forEach((key, value) {
        if (value is! Map) return;
        result[key.toString()] = CaseDonationStats(
          donorsCount: (value['donors'] as num?)?.toInt() ?? 0,
          raised: (value['raised'] as num?)?.toDouble() ?? 0,
        );
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(
    SharedPreferences prefs,
    Map<String, CaseDonationStats> map,
  ) async {
    final encoded = {
      for (final entry in map.entries)
        entry.key: {
          'donors': entry.value.donorsCount,
          'raised': entry.value.raised,
        },
    };
    await prefs.setString(_key, jsonEncode(encoded));
  }
}
