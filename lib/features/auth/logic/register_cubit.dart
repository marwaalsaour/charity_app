import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/register_params.dart';
import '../data/repositories/auth_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _repository;

  RegisterCubit(this._repository) : super(const RegisterInitial());

  Future<void> register(RegisterParams params) async {
    emit(const RegisterLoading());

    try {
      await _repository.register(params);
      emit(const RegisterSuccess());
    } on ApiException catch (e) {
      emit(RegisterError(e.message));
    } catch (_) {
      emit(const RegisterError('auth_error_generic'));
    }
  }
}
