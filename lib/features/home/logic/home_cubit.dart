import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/home_campaign_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({HomeCampaignRepository? repository})
      : _repository = repository ?? HomeCampaignRepository(),
        super(HomeInitial());

  final HomeCampaignRepository _repository;
  List<String> get categoriesKeys => const [
    'categories.all',
    'categories.patients',
    'categories.education',
    'categories.environment',
    'categories.orphans',
  ];

  Future<void> loadHome() async {
    emit(HomeLoading());
    try {
      final campaigns = await _repository.getRecentCampaigns();
      emit(
        HomeLoaded(
          volunteers: 12,
          donors: 176,
          beneficiaries: 495,
          campaigns: campaigns,
        ),
      );
    } catch (e) {
      emit(HomeError('Failed to load home data'));
    }
  }

  void filterBySearch(String query) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(searchQuery: query));
    }
  }

  void filterByCategory(String categoryKey) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(selectedCategory: categoryKey));
    }
  }

  Future<void> refresh() => loadHome();
}
