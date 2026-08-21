import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../volunteer/data/repositories/volunteer_api_repository.dart';

class HomeStats {
  const HomeStats({
    required this.donors,
    required this.volunteers,
    required this.beneficiaries,
  });

  final int donors;
  final int volunteers;
  final int beneficiaries;

  static const empty = HomeStats(donors: 0, volunteers: 0, beneficiaries: 0);
}

class HomeStatsRepository {
  HomeStatsRepository({
    Dio? dio,
    VolunteerApiRepository? volunteerRepository,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _volunteerRepository =
            volunteerRepository ?? VolunteerApiRepository(dio: dio);

  final Dio _dio;
  final VolunteerApiRepository _volunteerRepository;

  static const _cacheKey = 'home_stats_api_v5';

  Future<HomeStats> fetchStats() async {
    final fromKpis = await _tryDashboardKpis();
    final volunteers =
        await _volunteerRepository.fetchTotalApprovedVolunteerCount();
    final cached = await _readCache();

    final stats = HomeStats(
      donors: fromKpis?.donors ?? cached?.donors ?? 0,
      volunteers: volunteers ?? fromKpis?.volunteers ?? cached?.volunteers ?? 0,
      beneficiaries:
          fromKpis?.beneficiaries ?? cached?.beneficiaries ?? 0,
    );

    if (fromKpis != null || volunteers != null) {
      await _writeCache(stats);
    }
    return stats;
  }

  /// Kept for callers after a donation; counters come from the API.
  Future<int> recordDonationSuccess() async {
    final stats = await fetchStats();
    return stats.donors;
  }

  Future<HomeStats?> _tryDashboardKpis() async {
    try {
      final response = await _dio.get('/dashboard/kpis');
      final data = response.data;
      if (data is! Map) return null;
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : Map<String, dynamic>.from(data);

      return HomeStats(
        donors: _toInt(payload['total_approved_donations']) ??
            _toInt(payload['total_donors']) ??
            _toInt(payload['donors']) ??
            0,
        volunteers: _toInt(payload['total_volunteers']) ??
            _toInt(payload['volunteers']) ??
            0,
        beneficiaries: _toInt(payload['accepted_requests']) ??
            _toInt(payload['total_beneficiaries']) ??
            _toInt(payload['beneficiaries']) ??
            0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<HomeStats?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donors = prefs.getInt('${_cacheKey}_donors');
      if (donors == null) return null;
      return HomeStats(
        donors: donors,
        volunteers: prefs.getInt('${_cacheKey}_volunteers') ?? 0,
        beneficiaries: prefs.getInt('${_cacheKey}_beneficiaries') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(HomeStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_cacheKey}_donors', stats.donors);
      await prefs.setInt('${_cacheKey}_volunteers', stats.volunteers);
      await prefs.setInt('${_cacheKey}_beneficiaries', stats.beneficiaries);
    } catch (_) {}
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(',', ''));
    return null;
  }
}
