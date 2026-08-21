import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'models/campaign_model.dart';
import 'models/search_suggestion.dart';

class SearchSuggestionHelper {
  static const _categoryKeys = [
  'categories.patients',
  'categories.education',
  'categories.environment',
  'categories.orphans',
  ];

  static const _trendingKeys = [
    'search_suggestions.urgent',
    'search_suggestions.education_support',
    'search_suggestions.medical_help',
    'search_suggestions.orphan_sponsorship',
    'search_suggestions.volunteer',
    'search_suggestions.environment',
  ];

  static List<SearchSuggestion> getSuggestions({
    required String query,
    required List<CampaignModel> campaigns,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _defaultSuggestions(campaigns);
    }
    return _matchingSuggestions(normalized, campaigns);
  }

  static List<SearchSuggestion> _defaultSuggestions(
    List<CampaignModel> campaigns,
  ) {
    final results = <SearchSuggestion>[];

    for (final key in _categoryKeys) {
      results.add(
        SearchSuggestion(
          label: key.tr(),
          query: key.tr(),
          kind: SuggestionKind.category,
          icon: _iconForCategory(key),
          categoryKey: key,
        ),
      );
    }

    final urgent = campaigns
        .where((c) => c.linkedDonation?.isUrgent == true)
        .take(2);
    for (final campaign in urgent) {
      results.add(_campaignSuggestion(campaign));
    }

    for (final key in _trendingKeys.take(3)) {
      results.add(
        SearchSuggestion(
          label: key.tr(),
          query: key.tr(),
          kind: SuggestionKind.trending,
          icon: Icons.trending_up_rounded,
        ),
      );
    }

    return results.take(8).toList();
  }

  static List<SearchSuggestion> _matchingSuggestions(
    String query,
    List<CampaignModel> campaigns,
  ) {
    final scored = <_ScoredSuggestion>[];

    for (final campaign in campaigns) {
      final title = campaign.displayTitle.toLowerCase();
      final category = campaign.categoryLabelKey.tr().toLowerCase();
      final score = _matchScore(query, title, category);
      if (score > 0) {
        scored.add(
          _ScoredSuggestion(
            score: score,
            suggestion: _campaignSuggestion(campaign),
          ),
        );
      }
    }

    for (final key in _categoryKeys) {
      final label = key.tr().toLowerCase();
      final score = _textScore(query, label);
      if (score > 0) {
        scored.add(
          _ScoredSuggestion(
            score: score + 5,
            suggestion: SearchSuggestion(
              label: key.tr(),
              query: key.tr(),
              kind: SuggestionKind.category,
              icon: _iconForCategory(key),
              categoryKey: key,
            ),
          ),
        );
      }
    }

    for (final key in _trendingKeys) {
      final label = key.tr().toLowerCase();
      final score = _textScore(query, label);
      if (score > 0) {
        scored.add(
          _ScoredSuggestion(
            score: score,
            suggestion: SearchSuggestion(
              label: key.tr(),
              query: key.tr(),
              kind: SuggestionKind.trending,
              icon: Icons.trending_up_rounded,
            ),
          ),
        );
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final seen = <String>{};
    final results = <SearchSuggestion>[];
    for (final item in scored) {
      final key = '${item.suggestion.kind.name}_${item.suggestion.label}';
      if (seen.add(key)) {
        results.add(item.suggestion);
      }
      if (results.length >= 6) break;
    }

    return results;
  }

  static SearchSuggestion _campaignSuggestion(CampaignModel campaign) {
    return SearchSuggestion(
      label: campaign.displayTitle,
      query: campaign.displayTitle,
      kind: SuggestionKind.campaign,
      icon: Icons.favorite_outline,
      subtitle: campaign.categoryLabelKey.tr(),
      campaign: campaign,
    );
  }

  static IconData _iconForCategory(String key) {
    return switch (key.split('.').last) {
      'patients' => Icons.medical_services_outlined,
      'education' => Icons.school_outlined,
      'environment' => Icons.eco_outlined,
      'orphans' => Icons.child_care_outlined,
      _ => Icons.category_outlined,
    };
  }

  static int _matchScore(String query, String title, String category) {
    final titleScore = _textScore(query, title);
    final categoryScore = _textScore(query, category);
    return titleScore > categoryScore ? titleScore + 10 : categoryScore;
  }

  static int _textScore(String query, String text) {
    if (text == query) return 100;
    if (text.startsWith(query)) return 80;
    if (text.contains(query)) return 50;

    final words = query.split(RegExp(r'\s+')).where((w) => w.length > 1);
    var partial = 0;
    for (final word in words) {
      if (text.contains(word)) partial += 30;
    }
    return partial;
  }
}

class _ScoredSuggestion {
  const _ScoredSuggestion({required this.score, required this.suggestion});

  final int score;
  final SearchSuggestion suggestion;
}
