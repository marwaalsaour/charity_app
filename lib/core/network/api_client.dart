import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          Headers.acceptHeader: 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isPublicAuthPath(options.path)) {
            handler.next(options);
            return;
          }
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            final value = token.startsWith('Bearer ')
                ? token
                : 'Bearer $token';
            options.headers['Authorization'] = value;
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final TokenStorage _tokenStorage = TokenStorage();
  late final Dio _dio;

  Dio get dio => _dio;

  static bool _isPublicAuthPath(String path) {
    return path.endsWith('/signin') || path.endsWith('/signup');
  }
}
