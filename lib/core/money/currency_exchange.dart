import '../../features/profile/data/models/wallet_currencies.dart';

/// Converts wallet currencies through a USD pivot so mixed donations can
/// be compared against a case's required amount.
class CurrencyExchange {
  CurrencyExchange._();

  /// Approximate USD value of 1 unit of each currency.
  static const usdPerUnit = <String, double>{
    'USD': 1,
    'EUR': 1.08,
    'SAR': 0.2666,
    'AED': 0.2723,
    'SYP': 0.00008, // 1 USD ≈ 12,500 SYP
  };

  static double toUsd(double amount, String currency) {
    final code = WalletCurrencies.normalizeCode(currency) ?? 'USD';
    return amount * (usdPerUnit[code] ?? 1);
  }

  static double fromUsd(double usdAmount, String currency) {
    final code = WalletCurrencies.normalizeCode(currency) ?? 'USD';
    final rate = usdPerUnit[code] ?? 1;
    if (rate == 0) return 0;
    return usdAmount / rate;
  }

  static double convert(double amount, String from, String to) {
    final source = WalletCurrencies.normalizeCode(from) ?? 'USD';
    final target = WalletCurrencies.normalizeCode(to) ?? 'USD';
    if (source == target) return amount;
    return fromUsd(toUsd(amount, source), target);
  }
}
