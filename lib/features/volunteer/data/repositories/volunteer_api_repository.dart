import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/auth_phone.dart';
import '../../../profile/data/volunteer_certificate_pdf.dart';

/// Volunteer APIs aligned with GitHub Amer-itdu/Ataa-Project.
class VolunteerApiRepository {
  VolunteerApiRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// Association volunteer application — POST /volunteer/apply
  Future<void> applyToAssociation({
    required String phone,
    required String gender,
    String? occupation,
    required int governorateId,
    required List<String> skills,
    String? availability,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/volunteer/apply',
        data: {
          'phone': AuthPhone.digitsOnly(phone),
          'gender': gender,
          if (occupation != null && occupation.isNotEmpty)
            'occupation': occupation,
          'governorate_id': governorateId,
          'skills': skills,
          if (availability != null && availability.isNotEmpty)
            'availability': availability,
          'description': description,
          'agreed_to_terms': true,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      if (data is Map && data['success'] == true) return;

      throw ApiException(
        _messageFrom(data) ?? 'donate_error_generic',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Field / campaign volunteering — POST /campaigns/volunteer/{id}
  Future<void> applyForCampaign({
    required int campaignId,
    String? notes,
    String? skills,
  }) async {
    if (campaignId <= 0) {
      throw const ApiException('donate_error_generic');
    }

    try {
      final response = await _dio.post(
        '/campaigns/volunteer/$campaignId',
        data: {
          'agreed_to_terms': true,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (skills != null && skills.isNotEmpty) 'skills': skills,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      if (data is Map && data['success'] == true) return;

      throw ApiException(
        _messageFrom(data) ?? 'donate_error_generic',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyApprovedCampaigns() async {
    return _fetchCampaignList('/my-campaigns/approved');
  }

  Future<List<Map<String, dynamic>>> fetchMyPendingCampaigns() async {
    return _fetchCampaignList('/my-campaigns/pending');
  }

  Future<({double totalHours, List<Map<String, dynamic>> entries})>
      fetchMyVolunteerHours() async {
    try {
      final response = await _dio.get('/my-volunteer-hours');
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        return (totalHours: 0.0, entries: <Map<String, dynamic>>[]);
      }

      final entriesRaw = data['entries'];
      final entries = <Map<String, dynamic>>[];
      if (entriesRaw is List) {
        for (final item in entriesRaw) {
          if (item is Map) {
            entries.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final total = data['total_hours'];
      var totalHours = total is num
          ? total.toDouble()
          : double.tryParse(total?.toString() ?? '') ?? 0;
      if (totalHours <= 0 && entries.isNotEmpty) {
        totalHours = entries.fold<double>(0, (sum, item) {
          final h = item['hours'];
          if (h is num) return sum + h.toDouble();
          return sum + (double.tryParse('$h') ?? 0);
        });
      }

      return (totalHours: totalHours, entries: entries);
    } catch (_) {
      return (totalHours: 0.0, entries: <Map<String, dynamic>>[]);
    }
  }

  /// GET /volunteer/certificate — official PDF from Laravel.
  Future<File> downloadCertificate({
    required String volunteerName,
    required double hours,
    required bool isArabic,
    int? userId,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _dio.get(
        '/volunteer/certificate',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {
            Headers.acceptHeader: 'application/pdf, application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final bytes = _asBytes(response.data);
      final status = response.statusCode ?? 0;
      final serverMessage = _messageFromBytes(bytes);

      if (status == 401) {
        throw const ApiException('volunteer_certificate_error', statusCode: 401);
      }

      if (status == 403) {
        throw ApiException(
          serverMessage ?? 'volunteer_certificate_hours_required',
          statusCode: 403,
        );
      }

      if (status == 200 && _isPdf(bytes)) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${VolunteerCertificatePdf.fileName}');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }

      if (status == 404) {
        final text = (serverMessage ?? '').toLowerCase();
        if (text.contains('volunteer profile')) {
          throw const ApiException(
            'volunteer_certificate_not_found',
            statusCode: 404,
          );
        }
      } else if (status != 0 && status != 404) {
        throw ApiException(
          serverMessage ?? 'volunteer_certificate_error',
          statusCode: status,
        );
      }
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final mapped = _mapError(e);
      if (mapped.statusCode == 403 || mapped.statusCode == 401) {
        throw mapped;
      }
      if (e.type != DioExceptionType.connectionTimeout &&
          e.type != DioExceptionType.receiveTimeout &&
          e.type != DioExceptionType.sendTimeout &&
          e.type != DioExceptionType.connectionError) {
        throw mapped;
      }
    }

    return VolunteerCertificatePdf.saveToTempFile(
      volunteerName: volunteerName,
      hours: hours.round(),
      isArabic: isArabic,
      userId: userId,
      phone: phone,
      email: email,
    );
  }

  static Uint8List _asBytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List(0);
  }

  static bool _isPdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  String? _messageFromBytes(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return _messageFrom(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Current association volunteer application — GET /volunteer/me
  Future<Map<String, dynamic>?> fetchMyAssociationApplication() async {
    try {
      final response = await _dio.get('/volunteer/me');
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      if (data['has_applied'] == false) return null;

      final volunteer = data['volunteer'];
      if (volunteer is Map) {
        return Map<String, dynamic>.from(volunteer);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> fetchSkillsList() async {
    try {
      final response = await _dio.get('/volunteer/skills');
      final data = response.data;
      if (data is! Map || data['success'] != true) return {};
      final skills = data['skills'];
      if (skills is! Map) return {};
      return skills.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static const _localCountKey = 'volunteer_local_count_v1';
  static const _countedIdsKey = 'volunteer_local_counted_ids_v1';

  /// Home + transparency volunteer card.
  /// API sum, then +1 on this device for each newly approved application
  /// (association or campaign) that was not counted yet.
  Future<int?> fetchTotalApprovedVolunteerCount() async {
    final apiCount = await _fetchRemoteVolunteerCount();
    return _mergeWithLocalApprovals(apiCount);
  }

  Future<int?> _fetchRemoteVolunteerCount() async {
    final counts = await Future.wait([
      _fetchListedCount(
        '/approved-general-volunteers',
        listKey: 'data',
      ),
      _fetchListedCount(
        '/volunteers/summary',
        listKey: 'data',
      ),
    ]);

    final association = counts[0];
    final campaigns = counts[1];
    if (association == null && campaigns == null) return null;
    return (association ?? 0) + (campaigns ?? 0);
  }

  Future<int> _mergeWithLocalApprovals(int? apiCount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIds = await _currentApprovalIds();
    final counted = prefs.getStringList(_countedIdsKey);
    var local = prefs.getInt(_localCountKey);

    if (counted == null) {
      local = apiCount ?? currentIds.length;
      await prefs.setStringList(_countedIdsKey, currentIds.toList());
      await prefs.setInt(_localCountKey, local);
      return local;
    }

    final known = counted.toSet();
    final newlyApproved = currentIds.difference(known);
    local ??= apiCount ?? 0;
    if (newlyApproved.isNotEmpty) {
      local += newlyApproved.length;
      known.addAll(newlyApproved);
      await prefs.setStringList(_countedIdsKey, known.toList());
    }
    if (apiCount != null && apiCount > local) {
      local = apiCount;
    }
    await prefs.setInt(_localCountKey, local);
    return local;
  }

  Future<Set<String>> _currentApprovalIds() async {
    final ids = <String>{};

    final association = await fetchMyAssociationApplication();
    final associationStatus = association?['status']?.toString().toLowerCase();
    if (associationStatus == 'approved' || associationStatus == 'active') {
      final id = association?['volunteer_id'] ?? association?['id'] ?? 'me';
      ids.add('association:$id');
    }

    final campaigns = await fetchMyApprovedCampaigns();
    for (final campaign in campaigns) {
      final id = campaign['id'] ?? campaign['campaign_id'];
      if (id == null) continue;
      ids.add('campaign:$id');
    }
    return ids;
  }

  Future<int?> _fetchListedCount(
    String path, {
    required String listKey,
  }) async {
    try {
      final response = await _dio.get(path);
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final listed = data[listKey];
      final fromList = listed is List ? listed.length : null;
      return _toInt(data['count']) ?? fromList;
    } catch (_) {
      return null;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchCampaignList(String path) async {
    try {
      final response = await _dio.get(path);
      final data = response.data;
      if (data is! Map || data['success'] != true) return [];
      final campaigns = data['campaigns'];
      if (campaigns is! List) return [];
      return campaigns
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final message = _messageFrom(e.response?.data);

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('auth_error_network');
    }

    if (status == 409) {
      return ApiException(
        message ?? 'volunteer_application_pending',
        statusCode: status,
      );
    }

    if (status == 422) {
      return ApiException(message ?? 'donate_error_generic', statusCode: status);
    }

    if (status == 400) {
      return ApiException(message ?? 'donate_error_generic', statusCode: status);
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    return ApiException(message ?? 'donate_error_generic', statusCode: status);
  }

  String? _messageFrom(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    return null;
  }
}
