import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../donations/data/case_donation_stats_cache.dart';
import '../../../donations/data/open_accepted_cases_cache.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../beneficiary_name_consent_cache.dart';
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
        'show_name': params.showBeneficiaryName ? '1' : '0',
      };
      if (params.showBeneficiaryName) {
        map['beneficiary_public_name'] = params.fullName.trim();
      }

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
            map['currency'] = params.currency;
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
          final schoolContact = await _resolvePatientContact(
            phone: params.phone,
            email: params.email,
          );
          if (schoolContact.phone != null) map['phone'] = schoolContact.phone;
          if (schoolContact.email != null) map['email'] = schoolContact.email;
          map['academic_grade'] = params.academicGrade!.trim();
          map['school_name'] = params.schoolName!.trim();
          map['family_book_photo'] = await MultipartFile.fromFile(
            params.familyBookPhoto!.path,
            filename: _fileName(params.familyBookPhoto!.path),
          );
        case BenefitRequestKind.university:
          final uniContact = await _resolvePatientContact(
            phone: params.phone,
            email: params.email,
          );
          if (uniContact.phone != null) map['phone'] = uniContact.phone;
          if (uniContact.email != null) map['email'] = uniContact.email;
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

      final requestJson = data['request'] ?? data['data'];
      var item = requestJson is Map
          ? BenefitRequestItem.fromJson(Map<String, dynamic>.from(requestJson))
          : BenefitRequestItem(
              id: DateTime.now().millisecondsSinceEpoch,
              requestType: params.kind.name,
              status: 'pending',
              createdAt: DateTime.now(),
              beneficiaryName: params.fullName,
              showBeneficiaryName: params.showBeneficiaryName,
              description: params.description,
              requiredAmount: params.requiredAmount ?? 0,
              currency: params.currency,
            );

      final typedName = params.fullName.trim();
      item = item.copyWith(
        beneficiaryName: typedName.isNotEmpty ? typedName : item.beneficiaryName,
        showBeneficiaryName:
            params.showBeneficiaryName || item.showBeneficiaryName,
        description: params.description.trim().isNotEmpty
            ? params.description.trim()
            : item.description,
        requiredAmount: params.requiredAmount ?? item.requiredAmount,
        currency: params.currency,
      );

      await BeneficiaryNameConsentCache.savePending(
        showName: params.showBeneficiaryName,
        name: typedName,
      );
      if (item.id > 0) {
        await BeneficiaryNameConsentCache.save(
          requestId: item.id,
          showName: item.showBeneficiaryName,
          name: typedName,
        );
      }

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

    List<BenefitRequestItem>? remoteFromMyRequests;
    try {
      final response = await _dio.get('/myrequests');
      final maps = _extractRequestMaps(response.data);
      if (maps.isNotEmpty || _isSuccessfulListResponse(response.data)) {
        final previous = await _readCache();
        final list = <BenefitRequestItem>[];
        for (final map in maps) {
          var model = BenefitRequestItem.fromJson(map);
          model = _preserveKnownDecision(model, previous);
          model = await _applyNameConsent(model, previous);
          list.add(model);
        }
        remoteFromMyRequests = list;
      }
    } catch (_) {
      // /myrequests is not registered on this API (404).
    }

    final cached = await _readCache();
    final seed = <BenefitRequestItem>[
      if (remoteFromMyRequests != null) ...remoteFromMyRequests,
      ...cached,
    ];
    final deduped = _dedupeById(seed);
    final withConsent = <BenefitRequestItem>[];
    for (final item in deduped) {
      withConsent.add(await _applyNameConsent(item, cached));
    }
    final withPending = await _attachPendingConsent(withConsent);
    final withNotifs = await _applyNotificationDecisions(withPending);
    final synced = await _syncStatusesFromServerLists(withNotifs);
    final withPrefs = await _applyLocalPayoutPreferences(synced);
    final withStats = await _applyLocalDonationStats(withPrefs);
    if (!_sameRequestList(withStats, cached)) {
      await _replaceCache(withStats);
    }

    final approvedMaps = [
      for (final item in withStats)
        if (item.isApproved) item.toJson(),
    ];
    if (approvedMaps.isNotEmpty) {
      await OpenAcceptedCasesCache.upsertCases(approvedMaps);
    }

    return withStats;
  }

  bool _sameRequestList(
    List<BenefitRequestItem> a,
    List<BenefitRequestItem> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].status != b[i].status ||
          a[i].donatedAmount != b[i].donatedAmount ||
          a[i].requiredAmount != b[i].requiredAmount ||
          a[i].payoutPreference != b[i].payoutPreference) {
        return false;
      }
    }
    return true;
  }

  /// This API has no /myrequests. Status is split across:
  /// pending: GET /getpending*
  /// accepted: GET /getopenaccepted*
  /// rejected: submitted locally, missing from both lists.
  Future<List<BenefitRequestItem>> _syncStatusesFromServerLists(
    List<BenefitRequestItem> local,
  ) async {
    final pending = await _loadPendingRequests();
    final accepted = await _loadLiveAcceptedById();

    final byId = <int, BenefitRequestItem>{
      for (final item in local)
        if (item.id > 0) item.id: item,
    };

    for (final item in pending.items) {
      if (item.id <= 0) continue;
      final existing = byId[item.id];
      if (existing == null) continue;
      byId[item.id] = existing.copyWith(status: 'pending');
    }

    for (final entry in accepted.entries) {
      final existing = byId[entry.key];
      if (existing == null) continue;
      if (existing.isRejected) continue;
      byId[entry.key] = existing.mergeFundingFrom(entry.value).copyWith(
            status: 'accepted',
          );
    }

    return byId.values.map((item) {
      if (accepted.containsKey(item.id)) {
        return item.isRejected
            ? item
            : item.copyWith(status: 'accepted');
      }
      if (pending.ids.contains(item.id)) {
        return item.copyWith(status: 'pending');
      }
      if (item.isApproved || item.isRejected) return item;
      if (!pending.fetchedOk || !_isServerRequestId(item.id)) return item;
      return item.copyWith(status: 'rejected');
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool _isServerRequestId(int id) => id > 0 && id < 1000000000;

  List<BenefitRequestItem> _dedupeById(List<BenefitRequestItem> items) {
    final byId = <int, BenefitRequestItem>{};
    for (final item in items) {
      if (item.id <= 0) continue;
      final previous = byId[item.id];
      byId[item.id] = previous == null
          ? item
          : previous.mergeFundingFrom(item);
    }
    return byId.values.toList();
  }

  Future<({bool fetchedOk, Set<int> ids, List<BenefitRequestItem> items})>
      _loadPendingRequests() async {
    final ids = <int>{};
    final items = <BenefitRequestItem>[];
    var fetchedOk = false;

    for (final endpoint in const [
      '/getpendingrequests',
      '/getpendingpatients',
      '/getpendingorphans',
      '/getpendingschools',
      '/getpendinguniversities',
    ]) {
      try {
        final response = await _dio.get(endpoint);
        fetchedOk = true;
        String? requestType;
        if (endpoint.contains('patient')) {
          requestType = 'patient';
        } else if (endpoint.contains('orphan')) {
          requestType = 'orphan';
        } else if (endpoint.contains('universit')) {
          requestType = 'university';
        } else if (endpoint.contains('school')) {
          requestType = 'school';
        }
        for (final map in _extractRequestMaps(response.data)) {
          if (requestType != null &&
              (map['request_type'] == null ||
                  map['request_type'].toString().isEmpty)) {
            map['request_type'] = requestType;
          }
          map['status'] = 'pending';
          final model = BenefitRequestItem.fromJson(map);
          if (model.id <= 0) continue;
          ids.add(model.id);
          items.add(model.copyWith(status: 'pending'));
        }
      } catch (_) {}
    }

    return (fetchedOk: fetchedOk, ids: ids, items: items);
  }

  Future<Map<int, BenefitRequestItem>> _loadLiveAcceptedById() async {
    final byId = <int, BenefitRequestItem>{};
    for (final endpoint in const [
      '/getopenacceptedpatients',
      '/getopenacceptedorphans',
      '/getopenacceptedschools',
      '/getopenaccepteduniversities',
      '/getopenacceptedrequests',
    ]) {
      try {
        final response = await _dio.get(endpoint);
        String? requestType;
        if (endpoint.contains('patient')) {
          requestType = 'patient';
        } else if (endpoint.contains('orphan')) {
          requestType = 'orphan';
        } else if (endpoint.contains('universit')) {
          requestType = 'university';
        } else if (endpoint.contains('school')) {
          requestType = 'school';
        }
        for (final map in _extractRequestMaps(response.data)) {
          if (requestType != null &&
              (map['request_type'] == null ||
                  map['request_type'].toString().isEmpty)) {
            map['request_type'] = requestType;
          }
          map['status'] = 'accepted';
          final model = BenefitRequestItem.fromJson(map);
          if (model.id <= 0) continue;
          final previous = byId[model.id];
          byId[model.id] =
              previous == null ? model : previous.mergeFundingFrom(model);
        }
      } catch (_) {}
    }
    if (byId.isNotEmpty) {
      await OpenAcceptedCasesCache.upsertCases([
        for (final item in byId.values) item.toJson(),
      ]);
    }
    return byId;
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
          (item.status == 'accepted' ||
              item.status == 'approved' ||
              item.status == 'rejected')) {
        changed.add(item);
      }
    }

    await prefs.setString(statusKey, jsonEncode(next));
    return changed;
  }

  /// Returns cases that just reached their requested amount.
  Future<List<BenefitRequestItem>> detectFullyFundedChanges(
    List<BenefitRequestItem> current,
  ) async {
    final scope = await _cacheScope();
    if (scope == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final key = _fundedCacheKey(scope);
    final raw = prefs.getString(key);
    final previous = <String>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          previous.addAll(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
    }

    final newlyFunded = <BenefitRequestItem>[];
    final next = {...previous};
    for (final item in current) {
      if (!item.isFullyFunded || item.id <= 0) continue;
      final id = item.id.toString();
      if (!previous.contains(id)) {
        newlyFunded.add(item);
      }
      next.add(id);
    }

    await prefs.setString(key, jsonEncode(next.toList()));
    return newlyFunded;
  }

  Future<BenefitRequestItem?> setPayoutPreference({
    required int requestId,
    required PayoutPreference preference,
  }) async {
    if (requestId <= 0 || preference == PayoutPreference.unset) return null;

    await _saveLocalPayoutPreference(requestId, preference);

    try {
      await _dio.post(
        '/requests/$requestId/payout-preference',
        data: {'preference': preference.storageValue},
      );
    } catch (_) {
      // Endpoint may not exist yet; local preference still applies.
    }

    final items = await _readCache();
    BenefitRequestItem? updated;
    final next = items.map((item) {
      if (item.id != requestId) return item;
      updated = item.copyWith(payoutPreference: preference);
      return updated!;
    }).toList();
    if (updated != null) {
      await _replaceCache(next);
    }
    return updated;
  }

  Future<List<BenefitRequestItem>> _applyLocalDonationStats(
    List<BenefitRequestItem> items,
  ) async {
    if (items.isEmpty) return items;
    final result = <BenefitRequestItem>[];
    for (final item in items) {
      final local = await CaseDonationStatsCache.get(item.id);
      if (local == null) {
        result.add(item);
        continue;
      }
      result.add(
        item.copyWith(
          donatedAmount: math.max(item.donatedAmount, local.raised),
          donorsCount: math.max(item.donorsCount, local.donorsCount),
          currency: item.currency.isNotEmpty ? item.currency : local.caseCurrency,
        ),
      );
    }
    return result;
  }

  Future<List<BenefitRequestItem>> _applyLocalPayoutPreferences(
    List<BenefitRequestItem> items,
  ) async {
    final prefsMap = await _readLocalPayoutPreferences();
    if (prefsMap.isEmpty) return items;
    return items.map((item) {
      final stored = prefsMap[item.id.toString()];
      if (stored == null || stored == PayoutPreference.unset) return item;
      if (item.payoutPreference != PayoutPreference.unset) return item;
      return item.copyWith(payoutPreference: stored);
    }).toList();
  }

  Future<Map<String, PayoutPreference>> _readLocalPayoutPreferences() async {
    final scope = await _cacheScope();
    if (scope == null) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_payoutCacheKey(scope));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): PayoutPreference.fromString(
            entry.value?.toString(),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalPayoutPreference(
    int requestId,
    PayoutPreference preference,
  ) async {
    final scope = await _cacheScope();
    if (scope == null) return;
    final current = await _readLocalPayoutPreferences();
    current[requestId.toString()] = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _payoutCacheKey(scope),
      jsonEncode({
        for (final entry in current.entries)
          entry.key: entry.value.storageValue,
      }),
    );
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

  BenefitRequestItem _preserveKnownDecision(
    BenefitRequestItem item,
    List<BenefitRequestItem> previous,
  ) {
    if (item.isRejected || item.isApproved) return item;
    for (final old in previous) {
      if (old.id != item.id) continue;
      if (old.isRejected) return item.copyWith(status: 'rejected');
      break;
    }
    return item;
  }

  Future<List<BenefitRequestItem>> _applyNotificationDecisions(
    List<BenefitRequestItem> items,
  ) async {
    if (items.isEmpty) return items;
    final notifications = await fetchServerNotifications();
    if (notifications.isEmpty) return items;

    var next = items;
    for (final n in notifications) {
      final decision = _decisionFromNotification(n);
      if (decision == null) continue;
      next = await applyDecision(
        approved: decision,
        current: next,
        requestId: _notificationRequestId(n),
        requestTitle: n['title']?.toString(),
      );
    }
    return next;
  }

  bool? _decisionFromNotification(Map<String, dynamic> n) {
    final type = [
      n['type'],
      n['notification_type'],
      n['key'],
      n['name'],
    ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
    final text = [
      n['title'],
      n['body'],
      n['message'],
    ].map((e) => e?.toString() ?? '').join(' ');
    final blob = '$type $text';

    if (blob.contains('volunteer') || blob.contains('تطوع')) return null;
    if (blob.contains('donation') && !blob.contains('request')) return null;

    if (type.contains('reject') ||
        type.contains('decline') ||
        text.contains('مرفوض') ||
        text.contains('تم رفض') ||
        text.contains('رفض الطلب') ||
        text.contains('لم تُقبل') ||
        text.contains('لم تقبل')) {
      return false;
    }
    if (type.contains('beneficiaryapproved') ||
        type.contains('beneficiary_approved') ||
        type.contains('requestapproved') ||
        text.contains('تمت الموافقة على الطلب') ||
        text.contains('تم قبول الطلب')) {
      return true;
    }
    return null;
  }

  int? _notificationRequestId(Map<String, dynamic> n) {
    final raw = n['request_id'] ??
        n['requestId'] ??
        n['assistance_request_id'] ??
        (n['data'] is Map ? (n['data'] as Map)['request_id'] : null);
    if (raw == null) return null;
    if (raw is int) return raw > 0 ? raw : null;
    return int.tryParse(raw.toString());
  }

  Future<BenefitRequestItem> _applyNameConsent(
    BenefitRequestItem item,
    List<BenefitRequestItem> previous,
  ) async {
    BenefitRequestItem? cached;
    for (final old in previous) {
      if (old.id == item.id) {
        cached = old;
        break;
      }
    }

    var show = item.showBeneficiaryName || (cached?.showBeneficiaryName ?? false);
    var name = (item.beneficiaryName != null &&
            item.beneficiaryName!.trim().isNotEmpty)
        ? item.beneficiaryName!.trim()
        : cached?.beneficiaryName?.trim();

    final stored = await BeneficiaryNameConsentCache.get(item.id);
    if (stored != null) {
      show = show || stored.showName;
      if (name == null || name.isEmpty) name = stored.name;
    }

    if (item.id > 0 && show && name != null && name.isNotEmpty) {
      await BeneficiaryNameConsentCache.save(
        requestId: item.id,
        showName: show,
        name: name,
      );
    }

    return item.copyWith(
      showBeneficiaryName: show,
      beneficiaryName: name,
    );
  }

  Future<List<BenefitRequestItem>> _attachPendingConsent(
    List<BenefitRequestItem> items,
  ) async {
    if (items.isEmpty) return items;
    final pending = await BeneficiaryNameConsentCache.peekPending();
    if (pending == null) return items;

    BenefitRequestItem? target;
    for (final item in items) {
      final sameName = item.beneficiaryName != null &&
          item.beneficiaryName!.trim().toLowerCase() ==
              pending.name.toLowerCase();
      if (sameName) {
        target = item;
        break;
      }
    }
    if (target == null) {
      for (final item in items) {
        if (!item.isPending) continue;
        if (target == null || item.createdAt.isAfter(target.createdAt)) {
          target = item;
        }
      }
    }
    if (target == null) return items;
    await BeneficiaryNameConsentCache.clearPending();

    if (target.id > 0) {
      await BeneficiaryNameConsentCache.save(
        requestId: target.id,
        showName: pending.showName,
        name: pending.name,
      );
    }

    final targetId = target.id;
    return [
      for (final item in items)
        item.id == targetId
            ? item.copyWith(
                showBeneficiaryName:
                    item.showBeneficiaryName || pending.showName,
                beneficiaryName: (item.beneficiaryName != null &&
                        item.beneficiaryName!.trim().isNotEmpty)
                    ? item.beneficiaryName
                    : pending.name,
              )
            : item,
    ];
  }

  Future<List<BenefitRequestItem>> applyDecision({
    required bool approved,
    List<BenefitRequestItem>? current,
    int? requestId,
    String? requestTitle,
  }) async {
    final items = current ?? await _readCache();
    if (items.isEmpty) return items;
    final nextStatus = approved ? 'accepted' : 'rejected';
    final title = requestTitle?.trim();

    bool matches(BenefitRequestItem item) {
      if (approved && item.isApproved) return false;
      if (!approved && item.isRejected) return false;
      final idMatch =
          requestId != null && requestId > 0 && item.id == requestId;
      final titleMatch = title != null &&
          title.isNotEmpty &&
          item.displayTitle.trim() == title;
      return idMatch || titleMatch;
    }

    var changed = false;
    var next = items.map((item) {
      if (!matches(item)) return item;
      changed = true;
      return item.copyWith(status: nextStatus);
    }).toList();

    if (!changed) {
      final pending = [
        for (final item in items)
          if (item.isPending) item,
      ];
      if (pending.length == 1) {
        final only = pending.first;
        next = [
          for (final item in items)
            item.id == only.id ? item.copyWith(status: nextStatus) : item,
        ];
        changed = true;
      }
    }

    if (changed) {
      await _replaceCache(next);
    }
    return next;
  }

  List<Map<String, dynamic>> _extractRequestMaps(dynamic data) {
    final result = <Map<String, dynamic>>[];

    void absorbList(dynamic list) {
      if (list is! List) return;
      for (final item in list) {
        if (item is Map) result.add(Map<String, dynamic>.from(item));
      }
    }

    if (data is List) {
      absorbList(data);
      return result;
    }
    if (data is! Map) return result;

    absorbList(data['data']);
    absorbList(data['requests']);
    absorbList(data['items']);
    absorbList(data['patients']);
    absorbList(data['orphans']);
    absorbList(data['schools']);
    absorbList(data['universities']);
    final nested = data['data'];
    if (nested is Map) {
      nested.forEach((_, value) {
        if (value is List) absorbList(value);
      });
    }
    return result;
  }

  bool _isSuccessfulListResponse(dynamic data) {
    if (data is List) return true;
    if (data is Map && data['success'] == true) {
      return data.containsKey('data') ||
          data.containsKey('requests') ||
          data.containsKey('items');
    }
    return false;
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

  String _fundedCacheKey(String userId) =>
      'my_benefit_request_funded_u_$userId';

  String _payoutCacheKey(String userId) =>
      'my_benefit_payout_pref_u_$userId';

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

  /// Ensures submit always has phone or email (API: email required_without phone).
  Future<({String? phone, String? email})> _resolvePatientContact({
    String? phone,
    String? email,
  }) async {
    var resolvedPhone = _digitsOnly(phone);
    var resolvedEmail = _validEmail(email);

    if (resolvedPhone != null || resolvedEmail != null) {
      return (phone: resolvedPhone, email: resolvedEmail);
    }

    // Prefer local cached profile first (faster / works offline briefly).
    try {
      final local = await _profileRepository.getProfile();
      if (local != null) {
        resolvedPhone = _digitsOnly(local.phone);
        resolvedEmail = _validEmail(local.email);
      }
    } catch (_) {}

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
