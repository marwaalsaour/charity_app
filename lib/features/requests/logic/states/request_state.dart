import '../../data/models/benefit_request_models.dart';
import '../../data/models/city_model.dart';
import '../../data/models/governorate_model.dart';

class RequestState {
  final int educationType;
  final int supportType;
  final bool isLoading;
  final bool isLoadingLocations;
  final bool isLoadingRequests;
  final String? submitError;
  final bool submitSuccess;
  final List<BenefitRequestItem> myRequests;

  final List<GovernorateModel> governorates;
  final List<CityModel> cities;

  final int? selectedGovernorateId;
  final int? selectedCityId;

  const RequestState({
    this.educationType = 0,
    this.supportType = 0,
    this.isLoading = false,
    this.isLoadingLocations = false,
    this.isLoadingRequests = false,
    this.submitError,
    this.submitSuccess = false,
    this.myRequests = const [],
    this.governorates = const [],
    this.cities = const [],
    this.selectedGovernorateId,
    this.selectedCityId,
  });

  RequestState copyWith({
    int? educationType,
    int? supportType,
    bool? isLoading,
    bool? isLoadingLocations,
    bool? isLoadingRequests,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitSuccess,
    List<BenefitRequestItem>? myRequests,
    List<GovernorateModel>? governorates,
    List<CityModel>? cities,
    int? selectedGovernorateId,
    int? selectedCityId,
    bool clearSelectedCity = false,
    bool clearSelectedGovernorate = false,
  }) {
    return RequestState(
      educationType: educationType ?? this.educationType,
      supportType: supportType ?? this.supportType,
      isLoading: isLoading ?? this.isLoading,
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSuccess: submitSuccess ?? this.submitSuccess,
      myRequests: myRequests ?? this.myRequests,
      governorates: governorates ?? this.governorates,
      cities: cities ?? this.cities,
      selectedGovernorateId: clearSelectedGovernorate
          ? null
          : (selectedGovernorateId ?? this.selectedGovernorateId),
      selectedCityId: clearSelectedCity
          ? null
          : (selectedCityId ?? this.selectedCityId),
    );
  }
}
