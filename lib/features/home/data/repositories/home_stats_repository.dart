import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../donations/data/repositories/donation_receipt_repository.dart';

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
    DonationReceiptRepository? receiptRepository,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _receiptRepository =
            receiptRepository ?? DonationReceiptRepository();

  final Dio _dio;
  final DonationReceiptRepository _receiptRepository;

  static const _donorsCountKey = 'home_real_donors_count_v1';

  Future<HomeStats> fetchStats() async {
    // GitHub backend has /dashboard/kpis (no /homestats).
    final fromKpis = await _tryDashboardKpis();
    final fromHome = fromKpis == null ? await _tryHomeStats() : null;
    final fromApi = fromKpis ?? fromHome;
    final localDonors = await _readLocalDonorsCount();
    final receiptCount = (await _receiptRepository.getReceipts()).length;

    final apiDonors = fromApi?.donors ?? 0;
    final donors = math.max(
      apiDonors,
      math.max(localDonors, receiptCount),
    );

    if (donors > localDonors) {
      await _writeLocalDonorsCount(donors);
    }

    return HomeStats(
      donors: donors,
      volunteers: fromApi?.volunteers ?? 0,
      beneficiaries: fromApi?.beneficiaries ?? 0,
    );
  }

  /// Call after every successful donation so the home counter increases by 1.
  Future<int> recordDonationSuccess() async {
    final local = await _readLocalDonorsCount();
    final next = local + 1;
    await _writeLocalDonorsCount(next);
    return next;
  }

  Future<HomeStats?> _tryHomeStats() async {
    try {
      final response = await _dio.get('/homestats');
      return _parse(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<HomeStats?> _tryDashboardKpis() async {
    try {
      final response = await _dio.get('/dashboard/kpis');
      final data = response.data;
      if (data is! Map) return null;
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : Map<String, dynamic>.from(data);

      // Each donation transaction counts as +1 donor contribution.
      final donors = _toInt(payload['total_donors']) ??
          _toInt(payload['total_approved_donations']) ??
          _toInt(payload['donors']) ??
          0;
      final volunteers = _toInt(payload['total_volunteers']) ??
          _toInt(payload['volunteers']) ??
          0;
      final beneficiaries = _toInt(payload['total_beneficiaries']) ??
          _toInt(payload['beneficiaries']) ??
          _toInt(payload['accepted_requests']) ??
          0;

      return HomeStats(
        donors: donors,
        volunteers: volunteers,
        beneficiaries: beneficiaries,
      );
    } catch (_) {
      return null;
    }
  }

  HomeStats? _parse(dynamic data) {
    if (data is! Map) return null;
    final payload = data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : Map<String, dynamic>.from(data);

    return HomeStats(
      donors: _toInt(payload['donors']) ??
          _toInt(payload['total_donors']) ??
          _toInt(payload['total_approved_donations']) ??
          0,
      volunteers: _toInt(payload['volunteers']) ??
          _toInt(payload['total_volunteers']) ??
          0,
      beneficiaries: _toInt(payload['beneficiaries']) ??
          _toInt(payload['total_beneficiaries']) ??
          _toInt(payload['accepted_requests']) ??
          0,
    );
  }

  Future<int> _readLocalDonorsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_donorsCountKey) ?? 0;
  }

  Future<void> _writeLocalDonorsCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_donorsCountKey, value < 0 ? 0 : value);
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
