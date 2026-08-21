import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/data/notification_helper.dart';
import '../../../profile/data/repositories/beneficiary_wallet_store.dart';
import '../../../donations/data/case_donation_stats_cache.dart';
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

    final newlyFunded = await repository.detectFullyFundedChanges(items);
    for (final item in newlyFunded) {
      await NotificationHelper.notifyCaseFullyFunded(
        requestTitle: item.displayTitle,
        amount: item.requiredAmount,
        currency: item.currency,
      );
    }

    final next = <BenefitRequestItem>[];
    for (final item in items) {
      if (item.isFullyFunded) {
        await _creditWalletForCompletedCase(item);
        next.add(item.copyWith(payoutPreference: PayoutPreference.wallet));
      } else {
        next.add(item);
      }
    }

    if (isClosed) return;
    emit(state.copyWith(myRequests: next, isLoadingRequests: false));
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

  Future<void> _creditWalletForCompletedCase(BenefitRequestItem item) async {
    final store = BeneficiaryWalletStore();
    if (await store.isRequestCredited(item.id)) {
      await repository.setPayoutPreference(
        requestId: item.id,
        preference: PayoutPreference.wallet,
      );
      return;
    }

    final stats = await CaseDonationStatsCache.get(item.id);
    final byCurrency = stats?.raisedByCurrency ?? const <String, double>{};
    if (byCurrency.values.any((value) => value > 0)) {
      await store.creditCurrencies(
        requestId: item.id,
        amounts: byCurrency,
      );
    } else if (item.requiredAmount > 0) {
      await store.creditRequest(
        requestId: item.id,
        amount: item.requiredAmount,
        currency: item.currency,
      );
    }

    await repository.setPayoutPreference(
      requestId: item.id,
      preference: PayoutPreference.wallet,
    );
  }

  Future<bool> setPayoutPreference(
    int requestId,
    PayoutPreference preference,
  ) async {
    final saved = await repository.setPayoutPreference(
      requestId: requestId,
      preference: preference,
    );
    BenefitRequestItem? updated = saved;
    if (updated == null) {
      for (final item in state.myRequests) {
        if (item.id == requestId) {
          updated = item.copyWith(payoutPreference: preference);
          break;
        }
      }
    }
    if (updated == null) return false;
    final credited = updated;

    if (preference == PayoutPreference.wallet && credited.requiredAmount > 0) {
      await BeneficiaryWalletStore().creditRequest(
        requestId: credited.id,
        amount: credited.requiredAmount,
        currency: credited.currency,
      );
    }

    final items = [
      for (final item in state.myRequests)
        item.id == credited.id ? credited : item,
    ];
    if (!isClosed) {
      emit(state.copyWith(myRequests: items));
    }
    return true;
  }
}
