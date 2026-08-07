import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/data/notification_helper.dart';
import '../../data/models/benefit_request_models.dart';
import '../../data/repositories/request_repository.dart';
import '../states/request_state.dart';

class RequestCubit extends Cubit<RequestState> {
  RequestCubit(this.repository) : super(const RequestState()) {
    loadGovernorates();
    loadMyRequests();
  }

  final RequestRepository repository;

  void changeEducationType(int type) =>
      emit(state.copyWith(educationType: type));

  void changeSupportType(int type) => emit(state.copyWith(supportType: type));

  Future<void> loadGovernorates() async {
    try {
      emit(state.copyWith(isLoadingLocations: true));
      final governorates = await repository.fetchGovernorates();
      if (isClosed) return;
      emit(
        state.copyWith(
          governorates: governorates,
          isLoadingLocations: false,
          clearSelectedCity: true,
          clearSelectedGovernorate: true,
          cities: const [],
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          governorates: const [],
          cities: const [],
          isLoadingLocations: false,
          clearSelectedCity: true,
          clearSelectedGovernorate: true,
        ),
      );
    }
  }

  Future<void> changeGovernorate(int id) async {
    try {
      emit(
        state.copyWith(
          selectedGovernorateId: id,
          clearSelectedCity: true,
          cities: const [],
          isLoadingLocations: true,
        ),
      );

      final cities = await repository.fetchCities(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          cities: cities,
          isLoadingLocations: false,
          clearSelectedCity: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          cities: const [],
          isLoadingLocations: false,
          clearSelectedCity: true,
        ),
      );
    }
  }

  void changeCity(int id) {
    emit(state.copyWith(selectedCityId: id));
  }

  Future<void> loadMyRequests() async {
    emit(state.copyWith(isLoadingRequests: true));
    final items = await repository.fetchMyRequests();
    final changed = await repository.detectStatusChanges(items);
    for (final item in changed) {
      if (item.isApproved) {
        await NotificationHelper.notifyBeneficiaryDecision(
          approved: true,
          requestTitle: item.displayTitle,
        );
      } else if (item.isRejected) {
        await NotificationHelper.notifyBeneficiaryDecision(
          approved: false,
          requestTitle: item.displayTitle,
        );
      }
    }

    // Also sync server-side notifications if the endpoint exists.
    final serverNotifs = await repository.fetchServerNotifications();
    for (final n in serverNotifs) {
      final type = n['type']?.toString() ?? '';
      final isRead = n['is_read'] == true;
      if (isRead) continue;
      if (type == 'beneficiaryApproved' || type == 'beneficiaryRejected') {
        await NotificationHelper.notifyBeneficiaryDecision(
          approved: type == 'beneficiaryApproved',
          requestTitle: n['title']?.toString() ?? '',
        );
      }
    }

    if (isClosed) return;
    emit(state.copyWith(myRequests: items, isLoadingRequests: false));
  }

  Future<bool> submitBenefitRequest(BenefitRequestSubmitParams params) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearSubmitError: true,
        submitSuccess: false,
      ),
    );
    try {
      final item = await repository.submitBenefitRequest(params);
      await NotificationHelper.notifyRequestSubmitted(
        requestTitle: item.displayTitle,
      );
      final items = await repository.fetchMyRequests();
      if (isClosed) return true;
      emit(
        state.copyWith(
          isLoading: false,
          submitSuccess: true,
          myRequests: items,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      final message = e is Exception ? e.toString() : 'request_submit_failed';
      emit(
        state.copyWith(
          isLoading: false,
          submitSuccess: false,
          submitError: message,
        ),
      );
      return false;
    }
  }

  String get supportTypeApiValue =>
      state.supportType == 0 ? 'laptopsupport' : 'tuitionassistance';
}
