import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _repository;

  RegisterCubit(this._repository) : super(const RegisterInitial());

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    emit(const RegisterLoading());

    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password,
      );
      emit(const RegisterSuccess());
    } catch (_) {
      emit(const RegisterError('auth_error_generic'));
    }
  }
}
