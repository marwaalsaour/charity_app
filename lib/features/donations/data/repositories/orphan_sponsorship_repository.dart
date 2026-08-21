import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/orphan_sponsorship_model.dart';

class OrphanSponsorshipRepository {
  static const _key = 'orphan_sponsorships_v1';

  Future<List<OrphanSponsorship>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => OrphanSponsorship.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OrphanSponsorship>> getActive() async {
    final all = await getAll();
    return all.where((e) => e.isActive && !e.isComplete).toList();
  }

  Future<OrphanSponsorship?> getById(String id) async {
    final all = await getAll();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> upsert(OrphanSponsorship sponsorship) async {
    final all = await getAll();
    final index = all.indexWhere((e) => e.id == sponsorship.id);
    if (index >= 0) {
      all[index] = sponsorship;
    } else {
      all.add(sponsorship);
    }
    await _save(all);
  }

  Future<void> _save(List<OrphanSponsorship> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
