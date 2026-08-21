import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../volunteer/data/repositories/volunteer_api_repository.dart';
import '../models/volunteer_activity_model.dart';

class VolunteerActivityRepository {
  VolunteerActivityRepository({
    Dio? dio,
    VolunteerApiRepository? apiRepository,
  })  : _api = apiRepository ?? VolunteerApiRepository(dio: dio ?? ApiClient.instance.dio);

  final VolunteerApiRepository _api;

  static const _storageKey = 'volunteer_activities';
  static const hoursPerSlot = 3;

  Future<List<VolunteerActivityModel>> getActivities() async {
    final remote = await _loadFromApi();
    if (remote.isNotEmpty) return remote;
    return _getLocalActivities();
  }

  Future<void> saveActivity(VolunteerActivityModel activity) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.add(jsonEncode(activity.toJson()));
    await prefs.setStringList(_storageKey, existing);
  }

  Future<int> getTotalHours() async {
    try {
      final hours = await _api.fetchMyVolunteerHours();
      if (hours.totalHours > 0 || hours.entries.isNotEmpty) {
        return hours.totalHours.round();
      }
    } catch (_) {}

    final activities = await _getLocalActivities();
    return activities.fold<int>(0, (sum, a) => sum + a.hours);
  }

  Future<List<CampaignVolunteerSummary>> getCampaignSummaries() async {
    final approved = await _api.fetchMyApprovedCampaigns();
    final pending = await _api.fetchMyPendingCampaigns();
    final hours = await _api.fetchMyVolunteerHours();

    final hoursByCampaign = <String, double>{};
    DateTime? lastFor(String campaignId) {
      DateTime? latest;
      for (final entry in hours.entries) {
        if (entry['campaign_id']?.toString() != campaignId) continue;
        final date = DateTime.tryParse(entry['date']?.toString() ?? '');
        if (date == null) continue;
        if (latest == null || date.isAfter(latest)) latest = date;
      }
      return latest;
    }

    for (final entry in hours.entries) {
      final id = entry['campaign_id']?.toString();
      if (id == null) continue;
      final h = entry['hours'];
      final value = h is num ? h.toDouble() : double.tryParse('$h') ?? 0;
      hoursByCampaign[id] = (hoursByCampaign[id] ?? 0) + value;
    }

    final map = <String, CampaignVolunteerSummary>{};

    void addCampaign(Map<String, dynamic> item, {required String status}) {
      final id = item['id']?.toString();
      if (id == null) return;
      final title = item['title']?.toString() ?? 'Campaign #$id';
      final myStatus = item['my_status']?.toString() ?? status;
      final location = item['location']?.toString() ??
          item['place']?.toString() ??
          '';
      map[id] = CampaignVolunteerSummary(
        campaignId: id,
        titleKey: title,
        locationKey: location.isNotEmpty ? location : myStatus,
        totalHours: (hoursByCampaign[id] ?? 0).round(),
        lastDate: lastFor(id) ??
            DateTime.tryParse(item['assigned_date']?.toString() ?? '') ??
            DateTime.now(),
        useTranslationKeys: false,
        status: myStatus,
      );
    }

    for (final item in approved) {
      addCampaign(item, status: 'approved');
    }
    for (final item in pending) {
      addCampaign(item, status: 'pending');
    }

    if (map.isNotEmpty) {
      final summaries = map.values.toList()
        ..sort((a, b) => b.lastDate.compareTo(a.lastDate));
      return summaries;
    }

    // Local fallback (field-volunteer slots saved offline).
    final activities = await _getLocalActivities();
    final localMap = <String, CampaignVolunteerSummary>{};
    for (final activity in activities) {
      final existing = localMap[activity.campaignId];
      if (existing == null) {
        localMap[activity.campaignId] = CampaignVolunteerSummary(
          campaignId: activity.campaignId,
          titleKey: activity.campaignTitleKey,
          locationKey: activity.locationKey,
          totalHours: activity.hours,
          lastDate: activity.date,
          useTranslationKeys: true,
        );
      } else {
        localMap[activity.campaignId] = CampaignVolunteerSummary(
          campaignId: existing.campaignId,
          titleKey: existing.titleKey,
          locationKey: existing.locationKey,
          totalHours: existing.totalHours + activity.hours,
          lastDate: activity.date.isAfter(existing.lastDate)
              ? activity.date
              : existing.lastDate,
          useTranslationKeys: existing.useTranslationKeys,
        );
      }
    }

    final summaries = localMap.values.toList()
      ..sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return summaries;
  }

  Future<List<VolunteerActivityModel>> _loadFromApi() async {
    final hours = await _api.fetchMyVolunteerHours();
    return hours.entries.map((entry) {
      final campaign = entry['campaign'];
      final title = campaign is Map
          ? campaign['title']?.toString() ?? 'Campaign'
          : 'Campaign';
      final hoursValue = entry['hours'];
      final h = hoursValue is num
          ? hoursValue.round()
          : int.tryParse('$hoursValue') ?? 0;
      return VolunteerActivityModel(
        id: entry['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        campaignId: entry['campaign_id']?.toString() ?? '0',
        campaignTitleKey: title,
        locationKey: entry['activity_description']?.toString() ?? '',
        hours: h,
        date: DateTime.tryParse(entry['date']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<VolunteerActivityModel>> _getLocalActivities() async {
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

  static int hoursFromSlotCount(int slotCount) => slotCount * hoursPerSlot;
}
