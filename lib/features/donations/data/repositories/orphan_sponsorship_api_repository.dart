import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/orphan_sponsorship_model.dart';

/// Orphan sponsorship against Ataa-Project:
/// POST /orphanssponsor/{orphan_id}
/// GET /orphanssponsorship-info/{orphan_id}
/// DELETE /orphanssponsor/{orphan_id}
/// GET /orphans/my-sponsored/list
class OrphanSponsorshipApiRepository {
  OrphanSponsorshipApiRepository({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<OrphanSponsorship> sponsor({
    required int orphanId,
    int? requestId,
  }) async {
    try {
      return await _sponsorOnce(orphanId, requestId: requestId);
    } on ApiException catch (e) {
      final canRetryWithRequest = e.statusCode == 404 &&
          requestId != null &&
          requestId > 0 &&
          requestId != orphanId;
      if (!canRetryWithRequest) rethrow;
      debugPrint(
        '[sponsor] orphan $orphanId missing, retry requestId=$requestId',
      );
      return _sponsorOnce(requestId, requestId: requestId);
    }
  }

  Future<OrphanSponsorship> _sponsorOnce(
    int orphanId, {
    int? requestId,
  }) async {
    if (orphanId <= 0) {
      throw const ApiException('sponsor_orphan_missing');
    }

    try {
      final response = await _dio.post(
        '/orphanssponsor/$orphanId',
        data: <String, dynamic>{
          if (requestId != null && requestId > 0) 'request_id': requestId,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        debugPrint(
          '[sponsor] POST /orphanssponsor/$orphanId '
          'status=${response.statusCode} body=$data',
        );

        // "Already sponsored" means the operation actually succeeded
        // (e.g. a previous attempt, or the server finished after a client
        // timeout). Treat it as success instead of surfacing an error.
        final msg = (_messageFrom(data) ?? '').toLowerCase();
        if (msg.contains('already sponsored')) {
          final info = await fetchInfo(orphanId);
          if (info != null) return info;
        }

        throw ApiException(
          _userMessage(_messageFrom(data), statusCode: response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final info = await fetchInfo(orphanId);
      return info ??
          OrphanSponsorship(
            id: '$orphanId',
            orphanId: orphanId,
            childName: '',
            monthlyAmount: _toDouble(data['sponsorship_amount']),
            currency: 'USD',
            startedAt: DateTime.now(),
            nextChargeAt:
                DateTime.tryParse(
                  data['next_monthly_deduction']?.toString() ?? '',
                ) ??
                DateTime.now().add(const Duration(days: 30)),
            paidMonths: 1,
          );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      // Network/timeout error: the request may have reached the server and
      // completed even though we didn't get the response in time. Check
      // before telling the user it failed.
      final isTimeoutLike = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      if (isTimeoutLike) {
        final info = await fetchInfo(orphanId);
        if (info != null) return info;
      }
      throw _mapError(e);
    }
  }

  Future<List<OrphanSponsorship>> fetchMine() async {
    try {
      final response = await _dio.get(
        '/orphans/my-sponsored/list',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw ApiException(
          _userMessage(_messageFrom(data), statusCode: response.statusCode),
          statusCode: response.statusCode,
        );
      }
      final raw = data['data'] ?? data['orphans'];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map(
            (item) =>
                OrphanSponsorship.fromApi(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.apiOrphanId > 0)
          .toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<OrphanSponsorship?> fetchInfo(int orphanId) async {
    if (orphanId <= 0) return null;
    try {
      final response = await _dio.get('/orphanssponsorship-info/$orphanId');
      final data = response.data;
      if (data is! Map) return null;
      if (data['is_sponsored'] != true && data['success'] != true) return null;
      return OrphanSponsorship.fromInfoApi(
        Map<String, dynamic>.from(data),
        orphanId: orphanId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cancel(int orphanId) async {
    if (orphanId <= 0) {
      throw const ApiException('donate_error_generic');
    }
    try {
      final response = await _dio.delete(
        '/orphanssponsor/$orphanId',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return;
      throw ApiException(
        _userMessage(_messageFrom(data), statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final message = _messageFrom(e.response?.data);
    final lower = (message ?? '').toLowerCase();

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('auth_error_network');
    }

    if (status == 401 ||
        (message ?? '').toLowerCase().contains('unauthenticated')) {
      return const ApiException('auth_session_expired', statusCode: 401);
    }

    if (status == 400 && lower.contains('insufficient')) {
      return ApiException('donate_insufficient_balance', statusCode: status);
    }

    if (status == 400 && lower.contains('already sponsored')) {
      return ApiException('sponsor_already_taken', statusCode: status);
    }

    if (status == 404) {
      return ApiException('sponsor_orphan_missing', statusCode: status);
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    return ApiException(_userMessage(message, statusCode: status), statusCode: status);
  }

  String _userMessage(String? message, {int? statusCode}) {
    final lower = (message ?? '').toLowerCase();
    if (statusCode == 401 || lower.contains('unauthenticated')) {
      return 'auth_session_expired';
    }
    if (lower.contains('sqlstate') ||
        lower.contains('unknown column') ||
        lower.contains('column not found') ||
        lower.contains('error during sponsorship')) {
      return 'sponsor_db_schema';
    }
    if (statusCode == 404 ||
        lower.contains('no query results') ||
        lower.contains('model [app\\models\\orphan]')) {
      return 'sponsor_orphan_missing';
    }
    if (lower.contains('already sponsored')) return 'sponsor_already_taken';
    if (lower.contains('insufficient')) return 'donate_insufficient_balance';
    if (lower.contains('fully funded')) return 'donate_error_generic';
    if (lower.contains('request not found')) {
      return 'sponsor_orphan_missing';
    }
    final raw = message?.trim() ?? '';
    if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(raw)) return raw;
    return 'donate_error_generic';
  }

  String? _messageFrom(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }
}
