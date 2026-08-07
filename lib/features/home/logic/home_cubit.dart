import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/campaign_model.dart';
import '../data/repositories/home_campaign_repository.dart';
import '../data/repositories/home_stats_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    HomeCampaignRepository? repository,
    HomeStatsRepository? statsRepository,
  })  : _repository = repository ?? HomeCampaignRepository(),
        _statsRepository = statsRepository ?? HomeStatsRepository(),
        super(HomeInitial());

  final HomeCampaignRepository _repository;
  final HomeStatsRepository _statsRepository;
  bool _loading = false;

  List<String> get categoriesKeys => const [
        'categories.all',
        'categories.patients',
        'categories.education',
        'categories.environment',
        'categories.orphans',
      ];

  Future<void> loadHome({bool force = false}) async {
    // Keep existing UI when returning to Home tab (no blank spinner).
    if (!force && state is HomeLoaded) return;
    if (_loading && !force) return;

    _loading = true;
    final showLoading = state is! HomeLoaded;
    if (showLoading) emit(HomeLoading());

    try {
      final campaignsFuture = _repository.getRecentCampaigns();
      final statsFuture = _statsRepository.fetchStats();
      final campaigns = await campaignsFuture;
      final stats = await statsFuture;

      emit(
        HomeLoaded(
          volunteers: stats.volunteers,
          donors: stats.donors,
          beneficiaries: stats.beneficiaries,
          campaigns: List<CampaignModel>.from(campaigns),
        ),
      );
    } catch (e) {
      if (state is! HomeLoaded) {
        emit(HomeError('Failed to load home data'));
      }
    } finally {
      _loading = false;
    }
  }

  /// Refresh only the donor/volunteer/beneficiary counters (after a donation).
  Future<void> refreshStats() async {
    if (state is! HomeLoaded) {
      await loadHome();
      return;
    }
    final current = state as HomeLoaded;
    try {
      final stats = await _statsRepository.fetchStats();
      emit(
        current.copyWith(
          donors: stats.donors,
          volunteers: stats.volunteers,
          beneficiaries: stats.beneficiaries,
        ),
      );
    } catch (_) {
      // Keep existing numbers if refresh fails.
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

  Future<void> refresh() => loadHome(force: true);
}
