import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../models/register_params.dart';
import '../auth_phone.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    TokenStorage? tokenStorage,
    UserProfileRepository? profileRepository,
  }) : _dio = dio ?? ApiClient.instance.dio,
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _profileRepository = profileRepository ?? UserProfileRepository();

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final UserProfileRepository _profileRepository;

  /// Returns a human-readable FCM sync summary for on-screen debug.
  Future<String> login({
    required String input,
    required String password,
    String? userCategory,
  }) async {
    final isEmail = input.contains('@');
    ApiException? lastError;

    if (isEmail) {
      return _loginOnce(
        body: {
          'email': input.trim(),
          'password': password,
        },
        isEmail: true,
      );
    }

    for (final phone in AuthPhone.loginCandidates(input)) {
      try {
        return await _loginOnce(
          body: {
            'phone': phone,
            'password': password,
          },
          isEmail: false,
        );
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode != 401 &&
            e.statusCode != 403 &&
            e.statusCode != 422) {
          rethrow;
        }
      }
    }

    throw lastError ?? const ApiException('auth_error_wrong_phone');
  }

  Future<String> _loginOnce({
    required Map<String, dynamic> body,
    required bool isEmail,
  }) async {
    try {
      final response = await _dio.post(
        '/signin',
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      final token = _extractToken(data);
      if (token == null || token.isEmpty) {
        throw ApiException(
          _messageFrom(data) ??
              (isEmail ? 'auth_error_wrong_email' : 'auth_error_wrong_phone'),
          statusCode: response.statusCode,
        );
      }

      await _tokenStorage.saveToken(token);
      await syncProfile();
      unawaited(syncFcmTokenToBackend());
      return token;
    } on DioException catch (e) {
      throw _mapDioError(e, isEmail: isEmail);
    }
  }

  /// Sends the device FCM token to Laravel so the server can push notifications.
  Future<String> updateFcmToken(String fcmToken) async {
    final authToken = await _tokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) {
      // ignore: avoid_print
      print('RESPONSE STATUS: skipped');
      // ignore: avoid_print
      print('RESPONSE BODY: no auth token — request not sent');
      return 'FCM SKIP: no auth token';
    }
    if (fcmToken.trim().isEmpty) {
      // ignore: avoid_print
      print('RESPONSE STATUS: skipped');
      // ignore: avoid_print
      print('RESPONSE BODY: empty fcm token — request not sent');
      return 'FCM SKIP: empty fcm token';
    }

    try {
      final response = await _dio.post(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': fcmToken.trim()},
        options: Options(contentType: Headers.jsonContentType),
      );
      // ignore: avoid_print
      print('RESPONSE STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('RESPONSE BODY: ${response.data}');
      return 'FCM TOKEN: $fcmToken\nSTATUS: ${response.statusCode}\nBODY: ${response.data}';
    } on DioException catch (e) {
      // ignore: avoid_print
      print('RESPONSE STATUS: ${e.response?.statusCode}');
      // ignore: avoid_print
      print('RESPONSE BODY: ${e.response?.data}\nERR: ${e.message}');
      return 'FCM TOKEN: $fcmToken\nSTATUS: ${e.response?.statusCode}\nBODY: ${e.response?.data}\nERR: ${e.message}';
    }
  }

  /// Best-effort: read FCM token and POST it. Never throws to callers.
  Future<String> syncFcmTokenToBackend() async {
    try {
      if (Firebase.apps.isEmpty) {
        // ignore: avoid_print
        print('FCM TOKEN VALUE: null');
        // ignore: avoid_print
        print('RESPONSE STATUS: skipped');
        // ignore: avoid_print
        print('RESPONSE BODY: Firebase.apps is empty (not initialized)');
        return 'FCM SKIP: Firebase.apps is empty (not initialized)';
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        // ignore: avoid_print
        print('FCM TOKEN VALUE: null');
        // ignore: avoid_print
        print('RESPONSE STATUS: skipped');
        // ignore: avoid_print
        print('RESPONSE BODY: getToken() threw: $e');
        return 'FCM TOKEN VALUE: null\ngetToken() threw: $e';
      }

      // ignore: avoid_print
      print('FCM TOKEN VALUE: $fcmToken');

      if (fcmToken == null || fcmToken.isEmpty) {
        try {
          await FirebaseMessaging.instance.deleteToken();
          await Future<void>.delayed(const Duration(milliseconds: 800));
          fcmToken = await FirebaseMessaging.instance.getToken();
          // ignore: avoid_print
          print('FCM TOKEN VALUE: $fcmToken');
        } catch (e) {
          // ignore: avoid_print
          print('FCM TOKEN VALUE: null');
          // ignore: avoid_print
          print('RESPONSE STATUS: skipped');
          // ignore: avoid_print
          print('RESPONSE BODY: getToken retry threw: $e');
          return 'FCM TOKEN VALUE: null\ngetToken retry threw: $e';
        }
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        // ignore: avoid_print
        print('RESPONSE STATUS: skipped');
        // ignore: avoid_print
        print('RESPONSE BODY: fcm token is null — not sent to backend');
        return 'FCM SKIP: getToken() returned null/empty';
      }
      return await updateFcmToken(fcmToken);
    } catch (e) {
      // ignore: avoid_print
      print('FCM TOKEN VALUE: null');
      // ignore: avoid_print
      print('RESPONSE STATUS: skipped');
      // ignore: avoid_print
      print('RESPONSE BODY: syncFcmTokenToBackend failed: $e');
      return 'syncFcmTokenToBackend failed: $e';
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/signout');
    } on DioException {
      // Clear local session even if the remote call fails.
    } finally {
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseMessaging.instance.deleteToken();
        }
      } catch (_) {}
      await _tokenStorage.clearToken();
      await _profileRepository.clearSession();
    }
  }

  Future<UserProfileModel?> syncProfile() async {
    try {
      final response = await _dio.get('/userprofile');
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final user = data['user'];
      if (user is! Map) return null;

      final profile = UserProfileModel.fromApiUser(
        _userWithWallet(user, data),
        imageUrl: ApiConstants.storageUrl(user['profile_image']?.toString()),
      );

      await _profileRepository.saveProfile(profile);
      return profile;
    } on DioException {
      return null;
    }
  }

  /// POST /userprofile/update (multipart when uploading a new local image).
  Future<UserProfileModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    String? localImagePath,
  }) async {
    try {
      final map = <String, dynamic>{
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone': AuthPhone.normalize(phone),
        'address': address.trim(),
      };

      if (localImagePath != null &&
          localImagePath.isNotEmpty &&
          !localImagePath.startsWith('http://') &&
          !localImagePath.startsWith('https://')) {
        map['profile_image'] = await MultipartFile.fromFile(
          localImagePath,
          filename: _fileName(localImagePath),
        );
      }

      final response = await _dio.post(
        '/userprofile/update',
        data: FormData.fromMap(map),
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw ApiException(
          _messageFrom(data) ?? 'profile_update_failed',
          statusCode: response.statusCode,
        );
      }

      final user = data['user'];
      if (user is! Map) {
        final synced = await syncProfile();
        if (synced != null) return synced;
        throw const ApiException('profile_update_failed');
      }

      final profile = UserProfileModel.fromApiUser(
        _userWithWallet(user, data),
        imageUrl: ApiConstants.storageUrl(user['profile_image']?.toString()),
      );
      await _profileRepository.saveProfile(profile);
      return profile;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _messageFrom(e.response?.data);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const ApiException('auth_error_network');
      }
      if (status == 422) {
        throw ApiException(
          _firstValidationError(e.response?.data) ??
              message ??
              'profile_update_failed',
          statusCode: status,
        );
      }
      throw ApiException(
        message ?? 'profile_update_failed',
        statusCode: status,
      );
    }
  }

  Future<void> register(RegisterParams params) async {
    await _tokenStorage.clearToken();
    final map = <String, dynamic>{
      'first_name': params.firstName.trim(),
      'last_name': params.lastName.trim(),
      'password': params.password,
      'password_confirmation': params.passwordConfirmation,
      'address': params.address.trim(),
      'date_of_birth': params.dateOfBirthApi,
      'user_category': params.userCategory,
      'profile_image': await MultipartFile.fromFile(
        params.profileImage.path,
        filename: _fileName(params.profileImage.path),
      ),
    };

    final phone = params.phone?.trim();
    final email = params.email?.trim();
    if (phone != null && phone.isNotEmpty) {
      map['phone'] = AuthPhone.normalize(phone);
    }
    if (email != null && email.isNotEmpty) map['email'] = email;

    if (params.nationalIdImage != null) {
      map['national_id'] = await MultipartFile.fromFile(
        params.nationalIdImage!.path,
        filename: _fileName(params.nationalIdImage!.path),
      );
    }

    if (params.passportImage != null) {
      map['international_passport'] = await MultipartFile.fromFile(
        params.passportImage!.path,
        filename: _fileName(params.passportImage!.path),
      );
    }

    try {
      final response = await _dio.post('/signup', data: FormData.fromMap(map));
      final data = response.data;

      if (data is! Map || data['success'] != true) {
        throw ApiException(
          _messageFrom(data) ?? 'auth_error_generic',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _mapRegisterError(e);
    }
  }

  ApiException _mapRegisterError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('auth_error_network');
    }

    if (status == 409) {
      return ApiException(
        _messageFrom(data) ?? 'auth_error_already_exists',
        statusCode: status,
      );
    }

    if (status == 422) {
      final firstError = _firstValidationError(data);
      return ApiException(
        firstError ?? _messageFrom(data) ?? 'auth_error_generic',
        statusCode: status,
      );
    }

    return ApiException(
      _messageFrom(data) ?? 'auth_error_generic',
      statusCode: status,
    );
  }

  ApiException _mapDioError(DioException e, {required bool isEmail}) {
    final status = e.response?.statusCode;
    final message = _messageFrom(e.response?.data);

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('auth_error_network');
    }

    if (status == 401) {
      return ApiException(
        isEmail ? 'auth_error_wrong_email' : 'auth_error_wrong_phone',
        statusCode: status,
      );
    }

    if (status == 403) {
      return ApiException(
        message ??
            (isEmail ? 'auth_error_wrong_email' : 'auth_error_wrong_phone'),
        statusCode: status,
      );
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    return ApiException(message ?? 'auth_error_generic', statusCode: status);
  }

  Map<dynamic, dynamic> _userWithWallet(Map user, Map data) {
    final merged = Map<dynamic, dynamic>.from(user);
    merged['balances'] = {
      ...WalletCurrencies.parse(data['balances']),
      ...WalletCurrencies.parse(data['wallet']),
      ...WalletCurrencies.parse(data['wallets']),
      ...WalletCurrencies.parse(user['balances']),
      ...WalletCurrencies.parse(user['wallet']),
      ...WalletCurrencies.parse(user['wallets']),
    };
    return merged;
  }

  String? _extractToken(dynamic data) {
    if (data is! Map) return null;
    final direct = data['token'] ?? data['access_token'] ?? data['accessToken'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final nested = data['data'];
    if (nested is Map) {
      final token =
          nested['token'] ?? nested['access_token'] ?? nested['accessToken'];
      if (token != null && token.toString().trim().isNotEmpty) {
        return token.toString();
      }
    }
    final user = data['user'];
    if (user is Map) {
      final token =
          user['token'] ?? user['access_token'] ?? user['accessToken'];
      if (token != null && token.toString().trim().isNotEmpty) {
        return token.toString();
      }
    }
    return null;
  }

  String? _messageFrom(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
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
