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

  Future<double> getTotalHours() async {
    final hours = await _api.fetchMyVolunteerHours();
    return hours.totalHours;
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
      final titleAr = _localizedField(item, 'title', 'ar');
      final titleEn = _localizedField(item, 'title', 'en');
      final title = titleEn.isNotEmpty
          ? titleEn
          : (titleAr.isNotEmpty ? titleAr : '');
      final myStatus = item['my_status']?.toString() ?? status;
      var locationAr = _localizedField(item, 'location', 'ar');
      var locationEn = _localizedField(item, 'location', 'en');
      if (locationAr.isEmpty && locationEn.isEmpty) {
        locationEn = _localizedField(item, 'place', 'en');
        locationAr = _localizedField(item, 'place', 'ar');
        if (locationAr.isEmpty) locationAr = locationEn;
        if (locationEn.isEmpty) locationEn = locationAr;
      }
      map[id] = CampaignVolunteerSummary(
        campaignId: id,
        titleKey: title,
        titleAr: titleAr,
        titleEn: titleEn,
        locationKey: locationEn.isNotEmpty ? locationEn : locationAr,
        locationAr: locationAr,
        locationEn: locationEn,
        totalHours: (hoursByCampaign[id] ?? 0).round(),
        lastDate: lastFor(id) ??
            DateTime.tryParse(item['assigned_date']?.toString() ?? '') ??
            DateTime.now(),
        useTranslationKeys: _isTranslationKey(title),
        status: myStatus,
        type: item['type']?.toString() ?? '',
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
        campaignId: entry['campaign_id']?.toString() ??
            (campaign is Map ? campaign['id']?.toString() ?? '0' : '0'),
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
        .map((e) {
          try {
            return VolunteerActivityModel.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<VolunteerActivityModel>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static int hoursFromSlotCount(int slotCount) => slotCount * hoursPerSlot;

  static bool _isTranslationKey(String value) {
    return !value.contains(' ') &&
        value.contains('.') &&
        RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value);
  }

  static String _localizedField(
    Map<String, dynamic> item,
    String base,
    String languageCode,
  ) {
    final nested = item[base];
    if (nested is Map) {
      final fromMap = _stringFromLocaleMap(nested, languageCode);
      if (fromMap.isNotEmpty) return fromMap;
    }

    final translations = item['translations'];
    if (translations is Map) {
      final field = translations[base];
      if (field is Map) {
        final fromMap = _stringFromLocaleMap(field, languageCode);
        if (fromMap.isNotEmpty) return fromMap;
      }
    }

    final keys = languageCode == 'ar'
        ? ['${base}_ar', '${base}Ar', 'ar_$base', 'arabic_$base']
        : ['${base}_en', '${base}En', 'en_$base', 'english_$base'];
    for (final key in keys) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    return '';
  }

  static String _stringFromLocaleMap(
    Map<dynamic, dynamic> map,
    String languageCode,
  ) {
    final preferred = languageCode == 'ar'
        ? [map['ar'], map['arabic'], map['ar_title']]
        : [map['en'], map['english'], map['en_title']];
    for (final value in preferred) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }
}
