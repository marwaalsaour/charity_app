import 'package:flutter/material.dart';

import 'campaign_model.dart';

enum SuggestionKind { campaign, category, trending }

class SearchSuggestion {
  final String label;
  final String query;
  final SuggestionKind kind;
  final IconData icon;
  final String? subtitle;
  final CampaignModel? campaign;
  final String? categoryKey;

  const SearchSuggestion({
    required this.label,
    required this.query,
    required this.kind,
    required this.icon,
    this.subtitle,
    this.campaign,
    this.categoryKey,
  });
}
