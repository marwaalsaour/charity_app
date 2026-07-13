import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginInitial());

  Future<void> login({
    required String input,
    required String password,
  }) async {
    emit(const LoginLoading());

    try {
      final success = await _repository.login(
        input: input,
        password: password,
      );

      if (success) {
        emit(const LoginSuccess());
      } else {
        emit(LoginError(input.contains('@')
            ? 'auth_error_wrong_email'
            : 'auth_error_wrong_phone'));
      }
    } catch (_) {
      emit(const LoginError('auth_error_generic'));
    }
  }

  /// دخول مبدئي للتطوير — بدون التحقق من الحقول.
  Future<void> loginGuest() => login(input: 'guest', password: 'guest');
}
