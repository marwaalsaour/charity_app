import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/money/currency_exchange.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../campaigns/data/repositories/community_campaign_repository.dart';
import '../../../donations/data/case_donation_stats_cache.dart';
import '../../../donations/data/models/donation_model.dart';
import '../../../donations/data/repositories/donation_repository.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../../volunteer/data/repositories/volunteer_api_repository.dart';
import '../models/transparency_model.dart';

/// Public transparency file. Admin updates most stats and report files.
/// Total donations is the live sum of case + campaign donations in USD.
class TransparencyRepository {
  TransparencyRepository({
    Dio? dio,
    DonationRepository? donationRepository,
    CommunityCampaignRepository? campaignRepository,
    VolunteerApiRepository? volunteerRepository,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _donationRepository = donationRepository ?? DonationRepository(),
        _campaignRepository =
            campaignRepository ?? CommunityCampaignRepository(),
        _volunteerRepository =
            volunteerRepository ?? VolunteerApiRepository(dio: dio);

  final Dio _dio;
  final DonationRepository _donationRepository;
  final CommunityCampaignRepository _campaignRepository;
  final VolunteerApiRepository _volunteerRepository;

  static const _cacheKey = 'transparency_snapshot_v7';

  Future<TransparencyData> fetch() async {
    final remote = await _tryTransparency() ?? await _tryDashboardKpis();
    final volunteers =
        await _volunteerRepository.fetchTotalApprovedVolunteerCount();
    final reports = await _tryMonthlyReports();
    final annual = await _tryAnnualFromMonthlyDonations();
    final base = remote ?? (await _readCache()) ?? TransparencyData.empty;

    final apiTotal = base.stats.totalDonations;
    final totalUsd =
        apiTotal > 0 ? apiTotal : await _sumCasesAndCampaignsUsd();

    final data = base.copyWith(
      stats: base.stats.copyWith(
        totalDonations: totalUsd,
        currency: 'USD',
        volunteers: volunteers ?? base.stats.volunteers,
      ),
      annualReport: annual ?? base.annualReport,
      financialReport: reports ?? base.financialReport,
    );
    await _writeCache(data);
    return data;
  }

  Future<TransparencyData?> _tryTransparency() async {
    try {
      final response = await _dio.get('/transparency');
      final payload = _unwrap(response.data);
      if (payload == null) return null;
      return _parseTransparency(payload);
    } catch (_) {
      return null;
    }
  }

  Future<TransparencyData?> _tryDashboardKpis() async {
    try {
      final response = await _dio.get('/dashboard/kpis');
      final payload = _unwrap(response.data);
      if (payload == null) return null;
      return TransparencyData(
        stats: _parseStats(payload),
        annualReport: const TransparencyDocument(),
        financialReport: const TransparencyDocument(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<TransparencyDocument?> _tryMonthlyReports() async {
    final now = DateTime.now();
    try {
      final response = await _dio.get(
        '/reports/complete-disbursement/${now.year}/${now.month}',
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        return _tryDonationsReport(now);
      }
      final report = data['report'] is Map
          ? Map<String, dynamic>.from(data['report'] as Map)
          : Map<String, dynamic>.from(data);
      final summary = report['summary'] is Map
          ? Map<String, dynamic>.from(report['summary'] as Map)
          : report;
      final total = summary['total'] is Map
          ? Map<String, dynamic>.from(summary['total'] as Map)
          : summary;
      final amount = total['total_amount'] ??
          report['total_amount_usd'] ??
          total['total_amount_usd'];
      final period =
          report['period']?.toString() ?? '${now.month}/${now.year}';
      return TransparencyDocument(
        year: '${now.year}',
        period: period,
        summaryEn:
            'Disbursed this period: ${amount ?? 0} USD across campaigns and cases.',
        summaryAr:
            'المصروف خلال هذه الفترة: ${amount ?? 0} دولار للحملات والحالات.',
      );
    } catch (_) {
      return _tryDonationsReport(now);
    }
  }

  Future<TransparencyDocument?> _tryDonationsReport(DateTime now) async {
    try {
      final response = await _dio.get(
        '/reports/donations/${now.year}/${now.month}',
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final amount = data['total_amount_usd'];
      final count = data['donations_count'];
      final period = data['period']?.toString() ?? '${now.month}/${now.year}';
      return TransparencyDocument(
        year: '${now.year}',
        period: period,
        summaryEn: 'Donations this period: $count transactions, $amount USD.',
        summaryAr: 'تبرعات هذه الفترة: $count عملية، $amount دولار.',
      );
    } catch (_) {
      return null;
    }
  }

  Future<TransparencyDocument?> _tryAnnualFromMonthlyDonations() async {
    try {
      final response = await _dio.get('/dashboard/monthly-donations');
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final donations = data['donations'];
      if (donations is! List) return null;
      var total = 0.0;
      for (final item in donations) {
        if (item is! Map) continue;
        total += _toDouble(item['amount_usd']) ?? 0;
      }
      final year = DateTime.now().year.toString();
      return TransparencyDocument(
        year: year,
        period: year,
        summaryEn:
            'Last 12 months of recorded donations total ${total.toStringAsFixed(2)} USD.',
        summaryAr:
            'إجمالي التبرعات المسجّلة خلال آخر 12 شهراً ${total.toStringAsFixed(2)} دولار.',
      );
    } catch (_) {
      return null;
    }
  }

  Future<double> _sumCasesAndCampaignsUsd() async {
    var total = 0.0;
    final seenCaseIds = <int>{};
    final localStats = await CaseDonationStatsCache.loadAll();

    final cases = await _donationRepository.getAllOpenAccepted();
    for (final item in cases ?? const <DonationModel>[]) {
      seenCaseIds.add(item.id);
      total += _caseRaisedUsd(item, localStats[item.id.toString()]);
    }

    localStats.forEach((key, cached) {
      final id = int.tryParse(key) ?? 0;
      if (id <= 0 || seenCaseIds.contains(id)) return;
      total += _cachedRaisedUsd(cached);
    });

    final campaigns = await _campaignRepository.getCampaigns();
    for (final campaign in campaigns) {
      total += CurrencyExchange.toUsd(campaign.raised, 'USD');
    }

    return total < 0 ? 0 : total;
  }

  double _caseRaisedUsd(DonationModel item, CaseDonationStats? cached) {
    final usd = CurrencyExchange.toUsd(item.raised, item.displayCurrency);
    if (cached == null) return usd;
    final cachedUsd = _cachedRaisedUsd(cached);
    return cachedUsd > usd ? cachedUsd : usd;
  }

  double _cachedRaisedUsd(CaseDonationStats cached) {
    return CurrencyExchange.toUsd(cached.raised, cached.caseCurrency);
  }

  TransparencyData _parseTransparency(Map<String, dynamic> payload) {
    final statsRaw = payload['stats'] is Map
        ? Map<String, dynamic>.from(payload['stats'] as Map)
        : payload;

    return TransparencyData(
      stats: _parseStats(statsRaw),
      annualReport: _parseDocument(
        payload,
        nestedKey: 'annual_report',
        prefix: 'annual_report',
      ),
      financialReport: _parseDocument(
        payload,
        nestedKey: 'financial_report',
        prefix: 'financial_report',
      ),
      policyBody: _string(payload['policy_body'] ?? payload['transparency_policy']),
      policyBodyAr: _string(payload['policy_body_ar']),
      policyBodyEn: _string(payload['policy_body_en']),
      verificationBody: _string(
        payload['verification_body'] ?? payload['verification_process'],
      ),
      verificationBodyAr: _string(payload['verification_body_ar']),
      verificationBodyEn: _string(payload['verification_body_en']),
    );
  }

  TransparencyDocument _parseDocument(
    Map<String, dynamic> payload, {
    required String nestedKey,
    required String prefix,
  }) {
    final nested = payload[nestedKey] is Map
        ? Map<String, dynamic>.from(payload[nestedKey] as Map)
        : payload;

    return TransparencyDocument(
      year: _string(nested['year'] ?? payload['${prefix}_year']),
      period: _string(nested['period'] ?? payload['${prefix}_period']),
      summary: _string(nested['summary'] ?? payload['${prefix}_summary']),
      summaryAr: _string(nested['summary_ar'] ?? payload['${prefix}_summary_ar']),
      summaryEn: _string(nested['summary_en'] ?? payload['${prefix}_summary_en']),
      fileUrl: _fileUrl(
        nested['file_url'] ??
            nested['file'] ??
            nested['url'] ??
            payload['${prefix}_file'] ??
            payload['${prefix}_url'],
      ),
    );
  }

  TransparencyStats _parseStats(Map<String, dynamic> payload) {
    final usdDirect = _toDouble(
      payload['total_donations_usd'] ??
          payload['total_donations_in_usd'] ??
          payload['total_donated_usd'],
    );
    final sourceCode = WalletCurrencies.normalizeCode(
          payload['currency']?.toString() ??
              payload['donations_currency']?.toString(),
        ) ??
        'USD';
    final sourceAmount = _toDouble(
          payload['total_donations'] ??
              payload['total_donation_amount'] ??
              payload['donations_amount'] ??
              payload['total_raised'] ??
              payload['total_collected'],
        ) ??
        0;
    final totalUsd = usdDirect ??
        (sourceCode == 'USD'
            ? sourceAmount
            : CurrencyExchange.toUsd(sourceAmount, sourceCode));

    return TransparencyStats(
      totalDonations: totalUsd,
      currency: 'USD',
      beneficiaries: _toInt(
            payload['beneficiaries'] ??
                payload['total_beneficiaries'] ??
                payload['beneficiaries_count'] ??
                payload['accepted_requests'],
          ) ??
          0,
      volunteers: _toInt(
            payload['volunteers'] ??
                payload['total_volunteers'] ??
                payload['volunteers_count'],
          ) ??
          0,
      campaigns: _toInt(
            payload['campaigns'] ??
                payload['total_campaigns'] ??
                payload['campaigns_count'],
          ) ??
          0,
      updatedAt: _parseDate(
        payload['updated_at'] ??
            payload['stats_updated_at'] ??
            payload['last_updated_at'],
      ),
    );
  }

  Map<String, dynamic>? _unwrap(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    return map;
  }

  String? _fileUrl(dynamic raw) {
    final value = _string(raw);
    if (value == null) return null;
    return ApiConstants.storageUrl(value) ?? value;
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(',', '').trim());
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  Future<TransparencyData?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _parseTransparency(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(TransparencyData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'total_donations': data.stats.totalDonations,
          'currency': data.stats.currency,
          'beneficiaries': data.stats.beneficiaries,
          'volunteers': data.stats.volunteers,
          'campaigns': data.stats.campaigns,
          'updated_at': data.stats.updatedAt?.toIso8601String(),
          'annual_report_year': data.annualReport.year,
          'annual_report_period': data.annualReport.period,
          'annual_report_summary': data.annualReport.summary,
          'annual_report_summary_ar': data.annualReport.summaryAr,
          'annual_report_summary_en': data.annualReport.summaryEn,
          'annual_report_file': data.annualReport.fileUrl,
          'financial_report_year': data.financialReport.year,
          'financial_report_period': data.financialReport.period,
          'financial_report_summary': data.financialReport.summary,
          'financial_report_summary_ar': data.financialReport.summaryAr,
          'financial_report_summary_en': data.financialReport.summaryEn,
          'financial_report_file': data.financialReport.fileUrl,
          'policy_body': data.policyBody,
          'policy_body_ar': data.policyBodyAr,
          'policy_body_en': data.policyBodyEn,
          'verification_body': data.verificationBody,
          'verification_body_ar': data.verificationBodyAr,
          'verification_body_en': data.verificationBodyEn,
        }),
      );
    } catch (_) {}
  }
}
