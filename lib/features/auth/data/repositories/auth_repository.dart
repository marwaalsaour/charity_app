class AuthRepository {
  /// مؤقتاً للتطوير — أي محاولة دخول تنجح بدون حساب حقيقي.
  static const bool devBypassAuth = true;

  Future<bool> login({
    required String input,
    required String password,
  }) async {
    if (devBypassAuth) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    await Future.delayed(const Duration(seconds: 2));

    if (input.contains('@')) {
      return input == 'test@test.com' && password == '12345678';
    }

    return input == '912345678' && password == '12345678';
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
