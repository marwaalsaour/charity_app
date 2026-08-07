import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/donation_receipt_model.dart';

class DonationReceiptRepository {
  static const _storageKey = 'donation_receipts';

  Future<List<DonationReceiptModel>> getReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((e) => DonationReceiptModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveReceipt(DonationReceiptModel receipt) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    final receipts = existing
        .map(
          (e) => DonationReceiptModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .where((r) => r.id != receipt.id)
        .toList();
    receipts.add(receipt);
    await prefs.setStringList(
      _storageKey,
      receipts.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> replaceAll(List<DonationReceiptModel> receipts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      receipts.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
