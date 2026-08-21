import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

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
          'phone': phone,
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
      final totalHours = total is num
          ? total.toDouble()
          : double.tryParse(total?.toString() ?? '') ?? 0;

      return (totalHours: totalHours, entries: entries);
    } catch (_) {
      return (totalHours: 0.0, entries: <Map<String, dynamic>>[]);
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
