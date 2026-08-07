import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../case_donation_stats_cache.dart';
import '../models/donation_checkout_args.dart';
import '../models/donation_model.dart';
import '../models/donation_need_item.dart';
import '../open_accepted_cases_cache.dart';

class DonationRepository {
  DonationRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// Open accepted assistance requests for donors (home + category lists).
  ///
  /// Returns API data when the call succeeds (even if empty).
  /// Falls back to mocks only when the API is unreachable / errors.
  Future<List<DonationModel>> getDonations(DonationCategory category) async {
    final all = await getAllOpenAccepted();
    if (all != null) {
      return all.where((e) => e.category == category).toList();
    }
    return _mockDonations(category);
  }

  /// All open accepted cases across types — preferred source for home.
  ///
  /// `null` means every API source failed; empty list means success with no cases.
  Future<List<DonationModel>?> getAllOpenAccepted() async {
    final byId = <int, DonationModel>{};
    var anySuccess = false;

    final combined = await _tryFetchAllRequestsEndpoint();
    if (combined != null) {
      anySuccess = true;
      for (final item in combined) {
        byId[item.id] = item;
      }
    }

    final perCategory = await Future.wait([
      _tryFetchAccepted(DonationCategory.medical),
      _tryFetchAccepted(DonationCategory.education),
      _tryFetchAccepted(DonationCategory.orphans),
    ]);

    for (final list in perCategory) {
      if (list == null) continue;
      anySuccess = true;
      for (final item in list) {
        byId[item.id] = item;
      }
    }

    // Merge device cache (filled when beneficiary/API previously saw approvals).
    final cachedMaps = await OpenAcceptedCasesCache.loadCases();
    for (final json in cachedMaps) {
      final category = _categoryFromRequestType(
        json['request_type']?.toString(),
      );
      if (category == null) continue;
      final mapped = _mapRequest(json, category);
      if (mapped == null) continue;
      byId.putIfAbsent(mapped.id, () => mapped);
      anySuccess = true;
    }

    if (!anySuccess && byId.isEmpty) return null;

    if (byId.isNotEmpty) {
      await OpenAcceptedCasesCache.upsertCases([
        for (final item in byId.values) _donationToCacheMap(item),
      ]);
    }

    final items = byId.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return _enrichWithLocalStats(items);
  }

  Future<List<DonationModel>> _enrichWithLocalStats(
    List<DonationModel> items,
  ) async {
    final enriched = <DonationModel>[];
    for (final item in items) {
      if (item.donorCount > 0 || item.raised > 0) {
        await CaseDonationStatsCache.mergeFromServer(
          requestId: item.id,
          donorsCount: item.donorCount,
          raised: item.raised,
        );
      }
      final local = await CaseDonationStatsCache.get(item.id);
      enriched.add(
        item.copyWith(
          donorsCount: math.max(item.donorCount, local?.donorsCount ?? 0),
          raised: math.max(item.raised, local?.raised ?? 0),
        ),
      );
    }
    return enriched;
  }

  Map<String, dynamic> _donationToCacheMap(DonationModel item) {
    return {
      'id': item.id,
      'request_type': switch (item.category) {
        DonationCategory.medical => 'patient',
        DonationCategory.orphans => 'orphan',
        DonationCategory.education => 'school',
      },
      'title': item.nameKey,
      'description': item.descriptionKey,
      'required_amount': item.goal,
      'donated_amount': item.raised,
      'personal_picture': item.image,
      'status': 'accepted',
      'status_request': 'open',
      'show_beneficiary_name': item.showBeneficiaryName,
      'beneficiary_public_name': item.beneficiaryName,
      'residence': item.residence,
      'institution': item.institution,
      'deadline_at': item.deadlineAt?.toIso8601String(),
      'donors_count': item.donorsCount,
    };
  }

  Future<List<DonationModel>?> _tryFetchAllRequestsEndpoint() async {
    try {
      final response = await _dio.get('/getopenacceptedrequests');
      final maps = _extractMaps(response.data);
      if (maps.isNotEmpty) {
        await OpenAcceptedCasesCache.upsertCases(maps);
      }

      final items = <DonationModel>[];
      for (final json in maps) {
        final category = _categoryFromRequestType(
          json['request_type']?.toString(),
        );
        if (category == null) continue;
        final mapped = _mapRequest(json, category);
        if (mapped != null) items.add(mapped);
      }
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<List<DonationModel>?> _tryFetchAccepted(
    DonationCategory category,
  ) async {
    try {
      final endpoints = switch (category) {
        DonationCategory.medical => ['/getopenacceptedpatients'],
        DonationCategory.orphans => ['/getopenacceptedorphans'],
        DonationCategory.education => [
            '/getopenacceptedschools',
            '/getopenaccepteduniversities',
          ],
      };

      final items = <DonationModel>[];
      final rawMaps = <Map<String, dynamic>>[];

      for (final endpoint in endpoints) {
        final maps = await _fetchEndpointMaps(endpoint);
        rawMaps.addAll(maps);
        for (final json in maps) {
          // Ensure request_type is present for cache/home mapping.
          json.putIfAbsent(
            'request_type',
            () => switch (category) {
              DonationCategory.medical => 'patient',
              DonationCategory.orphans => 'orphan',
              DonationCategory.education =>
                endpoint.contains('universit') ? 'university' : 'school',
            },
          );
          final mapped = _mapRequest(json, category);
          if (mapped != null) items.add(mapped);
        }
      }

      if (rawMaps.isNotEmpty) {
        await OpenAcceptedCasesCache.upsertCases(rawMaps);
      }

      items.sort((a, b) => b.id.compareTo(a.id));
      return items;
    } catch (_) {
      return null;
    }
  }

  DonationCategory? _categoryFromRequestType(String? type) {
    switch (type?.toLowerCase().trim()) {
      case 'patient':
      case 'medical':
        return DonationCategory.medical;
      case 'orphan':
      case 'orphans':
        return DonationCategory.orphans;
      case 'school':
      case 'university':
      case 'education':
        return DonationCategory.education;
      default:
        return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEndpointMaps(String endpoint) async {
    final response = await _dio.get(endpoint);
    return _extractMaps(response.data);
  }

  List<Map<String, dynamic>> _extractMaps(dynamic data) {
    final list = <dynamic>[];

    if (data is List) {
      list.addAll(data);
    } else if (data is Map) {
      if (data['data'] is List) {
        list.addAll(data['data'] as List);
      } else if (data['requests'] is List) {
        list.addAll(data['requests'] as List);
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      result.add(Map<String, dynamic>.from(item));
    }
    return result;
  }

  DonationModel? _mapRequest(
    Map<String, dynamic> json,
    DonationCategory category,
  ) {
    final id = _toInt(json['id']);
    if (id == null || id <= 0) return null;

    final beneficiary = json['beneficiary'];
    final beneficiaryMap =
        beneficiary is Map ? Map<String, dynamic>.from(beneficiary) : null;
    final beneficiaryNameRaw = beneficiaryMap?['full_name']?.toString() ?? '';

    final showName = _toBool(json['show_beneficiary_name']);
    final publicName =
        (json['beneficiary_public_name']?.toString().trim().isNotEmpty == true)
            ? json['beneficiary_public_name'].toString().trim()
            : (showName && beneficiaryNameRaw.trim().isNotEmpty
                ? beneficiaryNameRaw.trim()
                : null);

    final residence = _resolveResidence(json, beneficiaryMap);
    final institution = _resolveInstitution(json);

    final title = (json['title']?.toString().trim().isNotEmpty == true)
        ? json['title'].toString().trim()
        : (publicName != null && publicName.isNotEmpty
            ? publicName
            : 'donation_case_fallback'.tr());

    final description =
        json['description']?.toString().trim().isNotEmpty == true
            ? json['description'].toString().trim()
            : 'donation_case_open_desc'.tr();

    final goal = _toDouble(json['required_amount']);
    final raised = _toDouble(json['donated_amount']);
    final imagePath = json['personal_picture']?.toString();
    final image = (imagePath != null &&
            (imagePath.startsWith('http://') ||
                imagePath.startsWith('https://') ||
                imagePath.startsWith('assets/')))
        ? imagePath
        : (ApiConstants.storageUrl(imagePath) ??
            'https://picsum.photos/600/400?random=$id');

    final donorsCount = _toInt(json['donors_count']) ??
        _toInt(json['donations_count']) ??
        _donationsListCount(json['donations']);

    final deadlineAt = _resolveDeadline(json);

    return DonationModel(
      id: id,
      nameKey: title,
      titleKey: category.titleKey.tr(),
      descriptionKey: description,
      category: category,
      raised: raised,
      goal: goal,
      image: image,
      isUrgent: (json['progress_percentage'] is num) &&
          (json['progress_percentage'] as num) < 30,
      useTranslationKeys: false,
      donateTargetType: DonationTargetType.request,
      donorsCount: donorsCount,
      deadlineAt: deadlineAt,
      showBeneficiaryName: publicName != null,
      beneficiaryName: publicName,
      residence: residence,
      institution: institution,
    );
  }

  String? _resolveResidence(
    Map<String, dynamic> json,
    Map<String, dynamic>? beneficiary,
  ) {
    final direct = json['residence']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final gov = beneficiary?['governorate'];
    final region = beneficiary?['region'];
    final govName = gov is Map ? gov['name']?.toString().trim() : null;
    final regionName = region is Map ? region['name']?.toString().trim() : null;
    final parts = <String>[
      if (govName != null && govName.isNotEmpty) govName,
      if (regionName != null && regionName.isNotEmpty) regionName,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' — ');
  }

  String? _resolveInstitution(Map<String, dynamic> json) {
    final direct = json['institution']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final school = json['school_student'] ?? json['schoolStudent'];
    if (school is Map) {
      final name = school['school_name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final uni = json['university_student'] ?? json['universityStudent'];
    if (uni is Map) {
      final name = uni['university_name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      final year = uni['academic_year']?.toString().trim();
      if (year != null && year.isNotEmpty) {
        return '${'academic_year'.tr()}: $year';
      }
    }

    return null;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return false;
  }

  DateTime _resolveDeadline(Map<String, dynamic> json) {
    final explicit = _parseDate(json['deadline_at']?.toString());
    if (explicit != null) return explicit;

    final daysLeft = _toInt(json['days_left']);
    if (daysLeft != null) {
      return DateTime.now().add(Duration(days: daysLeft));
    }

    final base = _parseDate(json['updated_at']?.toString()) ??
        _parseDate(json['created_at']?.toString()) ??
        DateTime.now();
    return base.add(const Duration(days: 30));
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
  }

  int? _donationsListCount(dynamic value) {
    if (value is List) return value.length;
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<DonationModel> _mockDonations(DonationCategory category) {
    const all = [
      DonationModel(
        id: 1,
        nameKey: 'donations.student_ahmed_name',
        titleKey: 'donations.student_ahmed_title',
        descriptionKey: 'donations.student_ahmed_story',
        category: DonationCategory.education,
        raised: 800,
        goal: 1200,
        image: 'assets/image/photo1.jpg',
        needs: [
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need1_title',
            descKey: 'donations.student_ahmed_need1_desc',
            amount: 700,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need2_title',
            descKey: 'donations.student_ahmed_need2_desc',
            amount: 300,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need3_title',
            descKey: 'donations.student_ahmed_need3_desc',
            amount: 200,
          ),
        ],
      ),
      DonationModel(
        id: 6,
        nameKey: 'donations.student_nour_name',
        titleKey: 'donations.student_nour_title',
        descriptionKey: 'donations.student_nour_story',
        category: DonationCategory.education,
        raised: 420,
        goal: 900,
        image: 'https://picsum.photos/600/400?random=36',
        isUrgent: true,
        needs: [
          DonationNeedItem(
            titleKey: 'donations.student_nour_need1_title',
            descKey: 'donations.student_nour_need1_desc',
            amount: 400,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_nour_need2_title',
            descKey: 'donations.student_nour_need2_desc',
            amount: 300,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_nour_need3_title',
            descKey: 'donations.student_nour_need3_desc',
            amount: 200,
          ),
        ],
      ),
      DonationModel(
        id: 7,
        nameKey: 'donations.student_karim_name',
        titleKey: 'donations.student_karim_title',
        descriptionKey: 'donations.student_karim_story',
        category: DonationCategory.education,
        raised: 1840,
        goal: 2400,
        image: 'assets/image/photo2.jpg',
        isUrgent: true,
        techTitleKey: 'technical_requirements',
        techDescKey: 'donations.student_karim_tech_desc',
        techTagKeys: [
          'donations.student_karim_tech_tag1',
          'donations.student_karim_tech_tag2',
        ],
      ),
      DonationModel(
        id: 2,
        nameKey: 'donations.patient_sara_name',
        titleKey: 'donations.patient_sara_title',
        descriptionKey: 'donations.patient_sara_story',
        category: DonationCategory.medical,
        raised: 1500,
        goal: 3000,
        image: 'assets/image/photo3.jpg',
        isUrgent: true,
        hospitalKey: 'donations.patient_sara_hospital',
        doctorKey: 'donations.patient_sara_doctor',
        storyKey: 'donations.patient_sara_full_story',
      ),
      DonationModel(
        id: 3,
        nameKey: 'donations.orphan_yusuf_name',
        titleKey: 'donations.orphan_yusuf_title',
        descriptionKey: 'donations.orphan_yusuf_desc',
        category: DonationCategory.orphans,
        raised: 2100,
        goal: 5000,
        image: 'assets/image/photo1.jpg',
      ),
      DonationModel(
        id: 8,
        nameKey: 'donations.orphan_layla_name',
        titleKey: 'donations.orphan_layla_title',
        descriptionKey: 'donations.orphan_layla_desc',
        category: DonationCategory.orphans,
        raised: 640,
        goal: 1800,
        image: 'https://picsum.photos/600/400?random=37',
      ),
      DonationModel(
        id: 9,
        nameKey: 'donations.orphan_mariam_name',
        titleKey: 'donations.orphan_mariam_title',
        descriptionKey: 'donations.orphan_mariam_desc',
        category: DonationCategory.orphans,
        raised: 920,
        goal: 2400,
        image: 'https://picsum.photos/600/400?random=38',
      ),
    ];

    return all.where((item) => item.category == category).toList();
  }
}
