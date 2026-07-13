import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/request_model.dart';
import '../../data/repositories/request_repository.dart';
import '../states/request_state.dart';

class RequestCubit extends Cubit<RequestState> {
  final RequestRepository repository;

  RequestCubit(this.repository) : super(const RequestState());

  void changeEducationType(int type) => emit(state.copyWith(educationType: type));
  void changeSupportType(int type) => emit(state.copyWith(supportType: type));

  Future<void> submitForm({
    required String type,
    required String name,
    required String contact,
    required String address,
    required String note,
    double? amount,
    String? grade,
    String? institution,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final model = RequestModel(
        type: type,
        fullName: name,
        contact: contact,
        address: address,
        description: note,
        amount: amount,
        academicGrade: grade,
        schoolUniversityName: institution,
        educationLevel: state.educationType,
        supportType: state.supportType,
      );

      await repository.submitNewRequest(model);
      emit(state.copyWith(isLoading: false));
      // هنا يمكن إضافة Success State لاحقاً
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      // هنا يمكن إضافة Error State
    }
  }
}