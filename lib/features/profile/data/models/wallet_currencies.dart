import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletCurrencies {
  WalletCurrencies._();

  static const codes = ['USD', 'EUR', 'SYP', 'SAR', 'AED'];

  static const Map<String, double> empty = {
    'USD': 0.0,
    'EUR': 0.0,
    'SYP': 0.0,
    'SAR': 0.0,
    'AED': 0.0,
  };

  static const _aliases = {
    'USD': 'USD',
    'DOLLAR': 'USD',
    'US DOLLAR': 'USD',
    'EUR': 'EUR',
    'EURO': 'EUR',
    'SYP': 'SYP',
    'LS': 'SYP',
    'LIRA': 'SYP',
    'SYRIAN POUND': 'SYP',
    'SAR': 'SAR',
    'RIYAL': 'SAR',
    'SAUDI RIYAL': 'SAR',
    'AED': 'AED',
    'DIRHAM': 'AED',
    'UAE DIRHAM': 'AED',
    'EMIRATI DIRHAM': 'AED',
  };

  static String nameKey(String code) => 'currency_${code.toLowerCase()}';

  static String symbol(String code, [Locale? locale]) {
    final isArabic = (locale?.languageCode ?? 'en') == 'ar';
    return switch (code.toUpperCase()) {
      'USD' => r'$',
      'EUR' => '€',
      'SYP' => isArabic ? 'ل.س' : 'SYP',
      'SAR' => isArabic ? 'ر.س' : 'SAR',
      'AED' => isArabic ? 'د.إ' : 'AED',
      _ => code,
    };
  }

  static Map<String, double> normalize(Map<String, double> raw) {
    return {for (final code in codes) code: raw[code] ?? 0};
  }

  static Map<String, double> merge(Iterable<Map<String, double>> sources) {
    final merged = <String, double>{};
    for (final source in sources) {
      source.forEach((key, value) {
        merged[key] = value;
      });
    }
    return normalize(merged);
  }

  static Map<String, double> parseAll(Map<dynamic, dynamic> source) {
    return merge([
      parse(source['balances']),
      parse(source['wallet']),
      parse(source['wallets']),
      parse(source['balance']),
      _parseNamedFields(source),
    ]);
  }

  static Map<String, double> parse(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      final result = <String, double>{};
      raw.forEach((key, value) {
        final code = normalizeCode(key?.toString());
        final amount = _toDouble(value);
        if (code != null && amount != null) result[code] = amount;
      });
      return result;
    }
    if (raw is List) {
      final result = <String, double>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final code = normalizeCode(
          item['currency']?.toString() ??
              item['currency_code']?.toString() ??
              item['code']?.toString(),
        );
        final amount = _toDouble(
          item['amount'] ?? item['balance'] ?? item['value'],
        );
        if (code != null && amount != null) result[code] = amount;
      }
      return result;
    }
    return {};
  }

  static String? normalizeCode(String? raw) {
    if (raw == null) return null;
    final key = raw.trim().toUpperCase().replaceAll('_', ' ');
    if (key.isEmpty) return null;
    return _aliases[key] ?? (codes.contains(key) ? key : null);
  }

  static String formatAmount(double amount, [Locale? locale]) {
    final language = locale?.toString() ?? 'en';
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0', language).format(amount);
    }
    return NumberFormat('#,##0.##', language).format(amount);
  }

  static String format(
    double amount,
    String code, {
    Locale locale = const Locale('en'),
  }) {
    final formatted = formatAmount(amount, locale);
    final sym = symbol(code, locale);
    if (locale.languageCode == 'ar') {
      return '$formatted $sym';
    }
    if (code == 'USD' || code == 'EUR') {
      return '$sym$formatted';
    }
    return '$formatted $sym';
  }

  static Map<String, double> _parseNamedFields(Map<dynamic, dynamic> source) {
    final result = <String, double>{};
    for (final code in codes) {
      final lower = code.toLowerCase();
      final amount = _toDouble(
        source[code] ??
            source[lower] ??
            source['${lower}_balance'] ??
            source['${code}_balance'] ??
            source['balance_$lower'],
      );
      if (amount != null) result[code] = amount;
    }
    return result;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    if (value is Map) {
      return _toDouble(value['amount'] ?? value['balance'] ?? value['value']);
    }
    return null;
  }
}
