import 'package:easy_localization/easy_localization.dart';

import '../data/models/campaign_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class HomeLoaded extends HomeState {
  final int volunteers;
  final int donors;
  final int beneficiaries;
  final List<CampaignModel> campaigns;
  final String selectedCategory;
  final String searchQuery;

  HomeLoaded({
    required this.volunteers,
    required this.donors,
    required this.beneficiaries,
    required this.campaigns,
    this.selectedCategory = 'categories.all',
    this.searchQuery = '',
  });

  List<CampaignModel> get filteredCampaigns {
    var list = campaigns;

    if (selectedCategory != 'categories.all') {
      final slug = selectedCategory.split('.').last;
      list = list.where((c) => c.category == slug).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) => _matchesSearch(c, q)).toList();
    }

    return list;
  }

  bool _matchesSearch(CampaignModel campaign, String query) {
    final title = campaign.displayTitle.toLowerCase();
    final category = campaign.categoryLabelKey.tr().toLowerCase();

    if (title.contains(query) || category.contains(query)) return true;

    final urgentHint = 'search_suggestions.urgent'.tr().toLowerCase();
    if (query.contains(urgentHint) || query.contains('urgent') || query.contains('عاجل')) {
      return campaign.linkedDonation?.isUrgent == true;
    }

    final words = query.split(RegExp(r'\s+')).where((w) => w.length > 1);
    for (final word in words) {
      if (title.contains(word) || category.contains(word)) return true;
    }

    return false;
  }

  HomeLoaded copyWith({
    int? volunteers,
    int? donors,
    int? beneficiaries,
    List<CampaignModel>? campaigns,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeLoaded(
      volunteers: volunteers ?? this.volunteers,
      donors: donors ?? this.donors,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      campaigns: campaigns ?? this.campaigns,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
