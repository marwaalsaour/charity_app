import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
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
      await _repository.login(
        input: input,
        password: password,
      );
      emit(const LoginSuccess());
    } on ApiException catch (e) {
      emit(LoginError(e.message));
    } catch (_) {
      emit(const LoginError('auth_error_generic'));
    }
  }
}
