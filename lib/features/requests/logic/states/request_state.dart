class RequestState {
  final int educationType;
  final int supportType;
  final bool isLoading;

  const RequestState({
    this.educationType = 0,
    this.supportType = 0,
    this.isLoading = false,
  });

  RequestState copyWith({
    int? educationType,
    int? supportType,
    bool? isLoading,
  }) {
    return RequestState(
      educationType: educationType ?? this.educationType,
      supportType: supportType ?? this.supportType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}