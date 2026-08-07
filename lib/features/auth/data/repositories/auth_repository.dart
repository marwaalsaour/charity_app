import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../models/register_params.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    TokenStorage? tokenStorage,
    UserProfileRepository? profileRepository,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _profileRepository = profileRepository ?? UserProfileRepository();

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final UserProfileRepository _profileRepository;

  Future<void> login({
    required String input,
    required String password,
  }) async {
    final isEmail = input.contains('@');
    final body = <String, dynamic>{
      if (isEmail) 'email': input.trim() else 'phone': input.trim(),
      'password': password,
    };

    try {
      final response = await _dio.post(
        '/signin',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data;

      if (data is! Map || data['success'] != true) {
        throw ApiException(
          _messageFrom(data) ?? 'auth_error_generic',
          statusCode: response.statusCode,
        );
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException('auth_error_generic');
      }

      await _tokenStorage.saveToken(token);
      await syncProfile();
    } on DioException catch (e) {
      throw _mapDioError(e, isEmail: isEmail);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/signout');
    } on DioException {
      // Clear local session even if the remote call fails.
    } finally {
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
        user,
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
        'phone': phone.trim(),
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
        user,
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
    if (phone != null && phone.isNotEmpty) map['phone'] = phone;
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
      final response = await _dio.post(
        '/signup',
        data: FormData.fromMap(map),
      );
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
      final lower = (message ?? '').toLowerCase();
      if (lower.contains('pending')) {
        return ApiException('auth_error_pending', statusCode: status);
      }
      if (lower.contains('rejected')) {
        return ApiException('auth_error_rejected', statusCode: status);
      }
      return ApiException(message ?? 'auth_error_generic', statusCode: status);
    }

    if (status != null && status >= 500) {
      return ApiException('auth_error_server', statusCode: status);
    }

    return ApiException(
      message ?? 'auth_error_generic',
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
