import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallet_currencies.dart';
import 'user_profile_repository.dart';

/// Local overlay of amounts credited to a beneficiary wallet after a
/// fully funded case is disbursed (used when the API does not credit yet).
class BeneficiaryWalletStore {
  BeneficiaryWalletStore({UserProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? UserProfileRepository();

  final UserProfileRepository _profileRepository;

  Future<Map<String, double>> loadBalances() async {
    final scope = await _profileRepository.getCurrentUserId();
    if (scope == null) return {};

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_balancesKey(scope));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return WalletCurrencies.parse(decoded);
    } catch (_) {
      return {};
    }
  }

  Future<bool> isRequestCredited(int requestId) async {
    final ids = await _creditedIds();
    return ids.contains(requestId.toString());
  }

  /// Credits each currency once per request. Returns false if already credited.
  Future<bool> creditCurrencies({
    required int requestId,
    required Map<String, double> amounts,
  }) async {
    if (requestId <= 0) return false;
    if (await isRequestCredited(requestId)) return false;

    final scope = await _profileRepository.getCurrentUserId();
    if (scope == null) return false;

    final current = await loadBalances();
    var creditedAny = false;
    amounts.forEach((rawCode, amount) {
      if (amount <= 0) return;
      final code = WalletCurrencies.normalizeCode(rawCode) ?? 'USD';
      current[code] = (current[code] ?? 0) + amount;
      creditedAny = true;
    });
    if (!creditedAny) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _balancesKey(scope),
      jsonEncode(WalletCurrencies.normalize(current)),
    );

    final ids = await _creditedIds();
    ids.add(requestId.toString());
    await prefs.setString(_creditedKey(scope), jsonEncode(ids.toList()));
    return true;
  }

  Future<bool> creditRequest({
    required int requestId,
    required double amount,
    required String currency,
  }) {
    return creditCurrencies(
      requestId: requestId,
      amounts: {currency: amount},
    );
  }

  Future<Set<String>> _creditedIds() async {
    final scope = await _profileRepository.getCurrentUserId();
    if (scope == null) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_creditedKey(scope));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  String _balancesKey(String userId) =>
      'beneficiary_wallet_credits_u_$userId';

  String _creditedKey(String userId) =>
      'beneficiary_wallet_credited_ids_u_$userId';
}
