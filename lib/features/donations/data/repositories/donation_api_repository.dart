import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/donation_checkout_args.dart';
import '../models/donation_receipt_model.dart';

class DonationApiRepository {
  DonationApiRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// Donate using wallet balance. Deducts from user balances on the server.
  Future<DonationReceiptModel> donate({
    required DonationCheckoutArgs args,
    required double amount,
    required String currency,
    required String donorName,
  }) async {
    try {
      final Response response;
      if (args.targetType == DonationTargetType.association ||
          args.targetId == null) {
        response = await _dio.post(
          '/quickDonate',
          data: {'amount': amount, 'currency': currency},
          options: Options(
            contentType: Headers.jsonContentType,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
      } else {
        final type = args.targetType == DonationTargetType.campaign
            ? 'campaign'
            : 'request';
        response = await _dio.post(
          '/donate/$type/${args.targetId}',
          data: {'amount': amount, 'currency': currency},
          options: Options(
            contentType: Headers.jsonContentType,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
      }

      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw ApiException(
          _messageFrom(data) ?? 'donate_error_generic',
          statusCode: response.statusCode,
        );
      }

      final donationId = data['donation_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final caseDonors = data['donors_count'];
      final caseRaised = data['donated_amount'];

      return DonationReceiptModel(
        id: donationId,
        donorName: donorName,
        recipientOrg: 'recipient_org',
        causeTitle: args.causeTitle,
        amount: amount,
        currency: currency,
        date: DateTime.now(),
        agent: 'receipt_agent_value',
        caseDonorsCount: caseDonors is num ? caseDonors.toInt() : null,
        caseRaisedAmount: caseRaised is num ? caseRaised.toDouble() : null,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetch donation history summary for the signed-in donor.
  Future<List<DonationReceiptModel>> fetchMyDonations({
    required String donorName,
  }) async {
    try {
      final response = await _dio.get('/mydonations');
      final data = response.data;
      if (data is! Map || data['success'] != true) return [];

      final payload = data['data'];
      if (payload is! Map) return [];

      final receipts = <DonationReceiptModel>[];

      final cases = payload['cases'];
      if (cases is List) {
        for (final item in cases) {
          if (item is! Map) continue;
          final id = item['donation_id']?.toString();
          if (id == null || id.isEmpty) continue;

          receipts.add(
            DonationReceiptModel(
              id: id,
              donorName: donorName,
              recipientOrg: 'recipient_org',
              causeTitle: _caseCauseTitle(item),
              amount: _toDouble(item['amount_usd']),
              currency: 'USD',
              date: _parseDate(item['date']?.toString()),
              agent: 'receipt_agent_value',
            ),
          );
        }
      }

      final campaigns = payload['campaigns'];
      if (campaigns is List) {
        for (final item in campaigns) {
          if (item is! Map) continue;
          final id = item['donation_id']?.toString();
          if (id == null || id.isEmpty) continue;

          receipts.add(
            DonationReceiptModel(
              id: id,
              donorName: donorName,
              recipientOrg: 'recipient_org',
              causeTitle: item['title']?.toString().isNotEmpty == true
                  ? item['title'].toString()
                  : 'Campaign',
              amount: _toDouble(item['amount_usd']),
              currency: 'USD',
              date: _parseDate(item['date']?.toString()),
              agent: 'receipt_agent_value',
            ),
          );
        }
      }

      receipts.sort((a, b) => b.date.compareTo(a.date));
      return receipts;
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  String _caseCauseTitle(Map item) {
    final type = item['type']?.toString() ?? '';
    // quickDonate targets the admin User — show association name key.
    if (type == 'User' || type.isEmpty) return 'recipient_org';
    return type;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
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

    if (status == 400 &&
        (message ?? '').toLowerCase().contains('insufficient')) {
      return ApiException('donate_insufficient_balance', statusCode: status);
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    return ApiException(
      message ?? 'donate_error_generic',
      statusCode: status,
    );
  }

  String? _messageFrom(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    return DateTime.tryParse(raw.replaceFirst(' ', 'T')) ?? DateTime.now();
  }
}
