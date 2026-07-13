import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/volunteer_activity_model.dart';

class VolunteerActivityRepository {
  static const _storageKey = 'volunteer_activities';
  static const hoursPerSlot = 3;

  Future<List<VolunteerActivityModel>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map(
          (e) => VolunteerActivityModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveActivity(VolunteerActivityModel activity) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.add(jsonEncode(activity.toJson()));
    await prefs.setStringList(_storageKey, existing);
  }

  Future<int> getTotalHours() async {
    final activities = await getActivities();
    return activities.fold<int>(0, (sum, a) => sum + a.hours);
  }

  Future<List<CampaignVolunteerSummary>> getCampaignSummaries() async {
    final activities = await getActivities();
    final map = <String, CampaignVolunteerSummary>{};

    for (final activity in activities) {
      final existing = map[activity.campaignId];
      if (existing == null) {
        map[activity.campaignId] = CampaignVolunteerSummary(
          campaignId: activity.campaignId,
          titleKey: activity.campaignTitleKey,
          locationKey: activity.locationKey,
          totalHours: activity.hours,
          lastDate: activity.date,
        );
      } else {
        map[activity.campaignId] = CampaignVolunteerSummary(
          campaignId: existing.campaignId,
          titleKey: existing.titleKey,
          locationKey: existing.locationKey,
          totalHours: existing.totalHours + activity.hours,
          lastDate: activity.date.isAfter(existing.lastDate)
              ? activity.date
              : existing.lastDate,
        );
      }
    }

    final summaries = map.values.toList()
      ..sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return summaries;
  }

  static int hoursFromSlotCount(int slotCount) => slotCount * hoursPerSlot;
}
