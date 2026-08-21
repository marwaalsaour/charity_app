import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/money/currency_exchange.dart';
import '../../profile/data/models/wallet_currencies.dart';

class CaseDonationStats {
  const CaseDonationStats({
    required this.donorsCount,
    required this.raised,
    this.caseCurrency = 'USD',
    this.raisedByCurrency = const {},
  });

  final int donorsCount;

  /// Raised equivalent in [caseCurrency].
  final double raised;
  final String caseCurrency;
  final Map<String, double> raisedByCurrency;
}

/// Local per-case donation stats so UI updates immediately after a successful
/// donate, even when Azure open-accepted payloads omit donors_count.
class CaseDonationStatsCache {
  static const _key = 'case_donation_stats_v2';
  static const _legacyKey = 'case_donation_stats_v1';

  static Future<void> recordDonation({
    required int requestId,
    required double amount,
    required String currency,
    String caseCurrency = 'USD',
  }) async {
    if (requestId <= 0 || amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    final current = map[requestId.toString()];
    final caseCode =
        WalletCurrencies.normalizeCode(caseCurrency) ??
        WalletCurrencies.normalizeCode(current?.caseCurrency) ??
        'USD';
    final donateCode = WalletCurrencies.normalizeCode(currency) ?? 'USD';

    final byCurrency = <String, double>{
      ...?current?.raisedByCurrency,
    };
    byCurrency[donateCode] = (byCurrency[donateCode] ?? 0) + amount;

    map[requestId.toString()] = CaseDonationStats(
      donorsCount: (current?.donorsCount ?? 0) + 1,
      raised: _equivalent(byCurrency, caseCode),
      caseCurrency: caseCode,
      raisedByCurrency: byCurrency,
    );
    await _write(prefs, map);
  }

  static Future<void> mergeFromServer({
    required int requestId,
    required int donorsCount,
    required double raised,
    String? caseCurrency,
  }) async {
    if (requestId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    final current = map[requestId.toString()];
    final caseCode = WalletCurrencies.normalizeCode(caseCurrency) ??
        WalletCurrencies.normalizeCode(current?.caseCurrency) ??
        'USD';
    final localEquivalent = current == null
        ? 0.0
        : _equivalent(current.raisedByCurrency, caseCode);
    map[requestId.toString()] = CaseDonationStats(
      donorsCount: donorsCount > (current?.donorsCount ?? 0)
          ? donorsCount
          : (current?.donorsCount ?? 0),
      raised: raised > localEquivalent ? raised : localEquivalent,
      caseCurrency: caseCode,
      raisedByCurrency: current?.raisedByCurrency ?? const {},
    );
    await _write(prefs, map);
  }

  static Future<CaseDonationStats?> get(int requestId) async {
    if (requestId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    final map = await _read(prefs);
    return map[requestId.toString()];
  }

  static Future<Map<String, CaseDonationStats>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  static double _equivalent(Map<String, double> byCurrency, String caseCode) {
    var total = 0.0;
    byCurrency.forEach((code, amount) {
      total += CurrencyExchange.convert(amount, code, caseCode);
    });
    return total;
  }

  static Future<Map<String, CaseDonationStats>> _read(
    SharedPreferences prefs,
  ) async {
    var raw = prefs.getString(_key);
    raw ??= prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, CaseDonationStats>{};
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final byCurrency = <String, double>{};
        final rawBy = value['by_currency'];
        if (rawBy is Map) {
          rawBy.forEach((k, v) {
            final code = WalletCurrencies.normalizeCode(k.toString());
            final amount = v is num ? v.toDouble() : double.tryParse('$v');
            if (code != null && amount != null) byCurrency[code] = amount;
          });
        }
        final caseCode = WalletCurrencies.normalizeCode(
              value['currency']?.toString(),
            ) ??
            'USD';
        final raised = (value['raised'] as num?)?.toDouble() ?? 0;
        result[key.toString()] = CaseDonationStats(
          donorsCount: (value['donors'] as num?)?.toInt() ?? 0,
          raised: byCurrency.isEmpty
              ? raised
              : _equivalent(byCurrency, caseCode),
          caseCurrency: caseCode,
          raisedByCurrency: byCurrency,
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
          'currency': entry.value.caseCurrency,
          'by_currency': entry.value.raisedByCurrency,
        },
    };
    await prefs.setString(_key, jsonEncode(encoded));
  }
}
