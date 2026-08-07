import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../donations/data/open_accepted_cases_cache.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../models/benefit_request_models.dart';
import '../models/city_model.dart';
import '../models/governorate_model.dart';

class RequestRepository {
  RequestRepository({
    Dio? dio,
    UserProfileRepository? profileRepository,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _profileRepository = profileRepository ?? UserProfileRepository();

  final Dio _dio;
  final UserProfileRepository _profileRepository;

  static const _legacyCacheKey = 'my_benefit_requests_cache';
  static const _legacyStatusKey = 'my_benefit_request_statuses';

  Future<List<GovernorateModel>> fetchGovernorates() async {
    try {
      final response = await _dio.get('/governorates');
      final data = response.data;
      if (data is! List) return [];

      final result = <GovernorateModel>[];
      for (final item in data) {
        if (item is! Map) continue;
        final model = GovernorateModel.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (model.id > 0 && model.name.isNotEmpty) result.add(model);
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<CityModel>> fetchCities(int governorateId) async {
    try {
      final response = await _dio.get('/governorates/$governorateId/regions');
      final data = response.data;
      if (data is! List) return [];

      final result = <CityModel>[];
      for (final item in data) {
        if (item is! Map) continue;
        final model = CityModel.fromJson(
          Map<String, dynamic>.from(item),
          governorateId: governorateId,
        );
        if (model.id > 0 && model.name.isNotEmpty) result.add(model);
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<BenefitRequestItem> submitBenefitRequest(
    BenefitRequestSubmitParams params,
  ) async {
    try {
      final endpoint = switch (params.kind) {
        BenefitRequestKind.patient => '/storepatient',
        BenefitRequestKind.orphan => '/storeorphan',
        BenefitRequestKind.school => '/storeschool',
        BenefitRequestKind.university => '/storeuniversity',
      };

      final map = <String, dynamic>{
        'full_name': params.fullName.trim(),
        'national_id': params.nationalId.trim(),
        'governorate_id': params.governorateId,
        'region_id': params.regionId,
        'description': params.description.trim(),
        'show_beneficiary_name': params.showBeneficiaryName ? '1' : '0',
      };

      switch (params.kind) {
        case BenefitRequestKind.patient:
          // Azure currently combines required_without + prohibited_if for is_self=true,
          // which rejects empty contact. Work around by always sending phone OR email
          // with is_self=false (same beneficiary data ends up stored).
          final contact = await _resolvePatientContact(
            phone: params.phone,
            email: params.email,
          );
          map['is_self'] = 'false';
          if (contact.phone != null) map['phone'] = contact.phone;
          if (contact.email != null) map['email'] = contact.email;
          if (params.requiredAmount != null) {
            map['required_amount'] = params.requiredAmount;
          }
          map['medical_report'] = await MultipartFile.fromFile(
            params.medicalReport!.path,
            filename: _fileName(params.medicalReport!.path),
          );
          map['national_id_document'] = await MultipartFile.fromFile(
            params.nationalIdDocument!.path,
            filename: _fileName(params.nationalIdDocument!.path),
          );
        case BenefitRequestKind.orphan:
          map['phone'] = params.phone!.trim().replaceAll(RegExp(r'\D'), '');
          map['family_booklet'] = await MultipartFile.fromFile(
            params.familyBooklet!.path,
            filename: _fileName(params.familyBooklet!.path),
          );
          map['father_death_certificate'] = await MultipartFile.fromFile(
            params.fatherDeathCertificate!.path,
            filename: _fileName(params.fatherDeathCertificate!.path),
          );
        case BenefitRequestKind.school:
          map['academic_grade'] = params.academicGrade!.trim();
          map['school_name'] = params.schoolName!.trim();
          map['family_book_photo'] = await MultipartFile.fromFile(
            params.familyBookPhoto!.path,
            filename: _fileName(params.familyBookPhoto!.path),
          );
        case BenefitRequestKind.university:
          map['academic_year'] = params.academicYear!.trim();
          map['support_type'] = params.supportType!;
          if (params.universityName != null &&
              params.universityName!.trim().isNotEmpty) {
            map['university_name'] = params.universityName!.trim();
          }
          map['university_id_photo'] = await MultipartFile.fromFile(
            params.universityIdPhoto!.path,
            filename: _fileName(params.universityIdPhoto!.path),
          );
      }

      final response = await _dio.post(
        endpoint,
        data: FormData.fromMap(map),
      );

      final data = response.data;
      if (data is! Map) {
        throw const ApiException('request_submit_failed');
      }

      final requestJson = data['request'];
      final item = requestJson is Map
          ? BenefitRequestItem.fromJson(Map<String, dynamic>.from(requestJson))
          : BenefitRequestItem(
              id: DateTime.now().millisecondsSinceEpoch,
              requestType: params.kind.name,
              status: 'pending',
              createdAt: DateTime.now(),
              beneficiaryName: params.fullName,
              description: params.description,
            );

      await _cacheUpsert(item);
      return item;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<BenefitRequestItem>> fetchMyRequests() async {
    final scope = await _cacheScope();
    if (scope == null) {
      await _clearLegacySharedCacheOnce();
      return [];
    }

    try {
      final response = await _dio.get('/myrequests');
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is List) {
        final list = <BenefitRequestItem>[];
        final acceptedMaps = <Map<String, dynamic>>[];
        for (final item in data['data'] as List) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final model = BenefitRequestItem.fromJson(map);
          list.add(model);
          if (model.isApproved) {
            map['status'] = 'accepted';
            map.putIfAbsent('status_request', () => 'open');
            acceptedMaps.add(map);
          }
        }
        await _replaceCache(list);
        if (acceptedMaps.isNotEmpty) {
          await OpenAcceptedCasesCache.upsertCases(acceptedMaps);
        }
        return list;
      }
    } catch (_) {
      // Fall through to cache + open-accepted sync when endpoint is missing.
    }

    final cached = await _readCache();
    final synced = await _syncAcceptedStatusFromPublicLists(cached);
    if (!_sameRequestList(synced, cached)) {
      await _replaceCache(synced);
    }

    final approvedMaps = [
      for (final item in synced)
        if (item.isApproved) item.toJson(),
    ];
    if (approvedMaps.isNotEmpty) {
      await OpenAcceptedCasesCache.upsertCases(approvedMaps);
    }

    return synced;
  }

  bool _sameRequestList(
    List<BenefitRequestItem> a,
    List<BenefitRequestItem> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].status != b[i].status) return false;
    }
    return true;
  }

  /// Azure may lack /myrequests; detect admin approval via open-accepted lists.
  Future<List<BenefitRequestItem>> _syncAcceptedStatusFromPublicLists(
    List<BenefitRequestItem> cached,
  ) async {
    if (cached.isEmpty) return cached;

    final pending = cached.where((e) => e.isPending && e.id > 0).toList();
    if (pending.isEmpty) return cached;

    final acceptedIds = <int>{};
    final acceptedMaps = <Map<String, dynamic>>[];
    for (final endpoint in const [
      '/getopenacceptedpatients',
      '/getopenacceptedorphans',
      '/getopenacceptedschools',
      '/getopenaccepteduniversities',
    ]) {
      try {
        final response = await _dio.get(endpoint);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map && data['data'] is List
                ? data['data'] as List
                : const []);
        for (final item in list) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final id = BenefitRequestItem.fromJson(map).id;
          if (id <= 0) continue;
          acceptedIds.add(id);
          map['status'] = 'accepted';
          map.putIfAbsent('status_request', () => 'open');
          if (endpoint.contains('patient')) {
            map.putIfAbsent('request_type', () => 'patient');
          } else if (endpoint.contains('orphan')) {
            map.putIfAbsent('request_type', () => 'orphan');
          } else if (endpoint.contains('universit')) {
            map.putIfAbsent('request_type', () => 'university');
          } else if (endpoint.contains('school')) {
            map.putIfAbsent('request_type', () => 'school');
          }
          acceptedMaps.add(map);
        }
      } catch (_) {
        // Ignore individual endpoint failures.
      }
    }

    if (acceptedMaps.isNotEmpty) {
      await OpenAcceptedCasesCache.upsertCases(acceptedMaps);
    }

    if (acceptedIds.isEmpty) return cached;

    return cached.map((item) {
      if (item.isPending && acceptedIds.contains(item.id)) {
        return BenefitRequestItem(
          id: item.id,
          requestType: item.requestType,
          status: 'accepted',
          title: item.title,
          description: item.description,
          createdAt: item.createdAt,
          beneficiaryName: item.beneficiaryName,
        );
      }
      return item;
    }).toList();
  }

  /// Returns items whose status changed since last check (for local notifications).
  Future<List<BenefitRequestItem>> detectStatusChanges(
    List<BenefitRequestItem> current,
  ) async {
    final scope = await _cacheScope();
    if (scope == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final statusKey = _statusCacheKey(scope);
    final raw = prefs.getString(statusKey);
    final previous = <String, String>{};
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          previous[k.toString()] = v.toString();
        });
      }
    }

    final changed = <BenefitRequestItem>[];
    final next = <String, String>{};
    for (final item in current) {
      final key = item.id.toString();
      next[key] = item.status;
      final old = previous[key];
      if (old != null &&
          old != item.status &&
          (item.status == 'accepted' || item.status == 'rejected')) {
        changed.add(item);
      }
    }

    await prefs.setString(statusKey, jsonEncode(next));
    return changed;
  }

  Future<List<Map<String, dynamic>>> fetchServerNotifications() async {
    try {
      final response = await _dio.get('/mynotifications');
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BenefitRequestItem>> _readCache() async {
    await _clearLegacySharedCacheOnce();
    final scope = await _cacheScope();
    if (scope == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_requestsCacheKey(scope)) ?? [];
    return raw
        .map(
          (e) => BenefitRequestItem.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _replaceCache(List<BenefitRequestItem> items) async {
    final scope = await _cacheScope();
    if (scope == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _requestsCacheKey(scope),
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _cacheUpsert(BenefitRequestItem item) async {
    final existing = await _readCache();
    final filtered = existing.where((e) => e.id != item.id).toList();
    filtered.insert(0, item);
    await _replaceCache(filtered);
  }

  Future<String?> _cacheScope() async {
    return _profileRepository.getCurrentUserId();
  }

  String _requestsCacheKey(String userId) =>
      'my_benefit_requests_cache_u_$userId';

  String _statusCacheKey(String userId) =>
      'my_benefit_request_statuses_u_$userId';

  Future<void> _clearLegacySharedCacheOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_legacyCacheKey)) {
      await prefs.remove(_legacyCacheKey);
    }
    if (prefs.containsKey(_legacyStatusKey)) {
      await prefs.remove(_legacyStatusKey);
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('auth_error_network');
    }

    if (status == 422) {
      return ApiException(
        _firstValidationError(data) ?? 'request_validation_failed',
        statusCode: status,
      );
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    final message = data is Map ? data['message']?.toString() : null;
    return ApiException(
      message ?? 'request_submit_failed',
      statusCode: status,
    );
  }

  /// Ensures patient submit always has phone or email (API validation requirement).
  Future<({String? phone, String? email})> _resolvePatientContact({
    String? phone,
    String? email,
  }) async {
    var resolvedPhone = _digitsOnly(phone);
    var resolvedEmail = _validEmail(email);

    if (resolvedPhone != null || resolvedEmail != null) {
      return (phone: resolvedPhone, email: resolvedEmail);
    }

    try {
      final response = await _dio.get('/userprofile');
      final data = response.data;
      if (data is Map && data['success'] == true && data['user'] is Map) {
        final user = Map<String, dynamic>.from(data['user'] as Map);
        resolvedPhone = _digitsOnly(user['phone']?.toString());
        resolvedEmail = _validEmail(user['email']?.toString());
      }
    } catch (_) {
      // Fall through to validation error below.
    }

    if (resolvedPhone == null && resolvedEmail == null) {
      throw const ApiException('request_contact_required');
    }

    return (phone: resolvedPhone, email: resolvedEmail);
  }

  String? _digitsOnly(String? value) {
    if (value == null) return null;
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  String? _validEmail(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) return null;
    return trimmed;
  }

  String? _firstValidationError(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is String && first.trim().isNotEmpty) return first;
      } else if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'file.jpg' : parts.last;
  }
}
