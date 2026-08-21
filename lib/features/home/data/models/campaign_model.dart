import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../campaigns/data/models/community_campaign_model.dart';
import '../../../donations/data/models/donation_model.dart';
import '../../../profile/data/models/wallet_currencies.dart';

class CampaignModel {
  final String id;
  final String titleKey;
  /// patients | education | environment | orphans
  final String category;
  final String? categoryDisplayKey;
  final String imageUrl;
  final double progress;
  final double goal;
  final double raised;
  final DonationModel? linkedDonation;
  final CommunityCampaignModel? linkedCommunity;

  const CampaignModel({
    required this.id,
    required this.titleKey,
    required this.category,
    this.categoryDisplayKey,
    required this.imageUrl,
    required this.progress,
    required this.goal,
    required this.raised,
    this.linkedDonation,
    this.linkedCommunity,
  });

  double get progressPercent => progress * 100;

  bool get isFullyFunded =>
      linkedDonation?.isFullyFunded ??
      linkedCommunity?.isFullyFunded ??
      (goal > 0 && raised >= goal);

  String formattedGoal([Locale? locale]) {
    final code = linkedDonation?.displayCurrency ?? 'USD';
    return WalletCurrencies.format(
      goal,
      code,
      locale: locale ?? const Locale('en'),
    );
  }

  String get displayTitle {
    if (linkedDonation != null) return linkedDonation!.cardTitle;
    if (linkedCommunity != null) return linkedCommunity!.displayTitle;
    return titleKey.tr();
  }

  String get categoryLabelKey {
    if (linkedCommunity != null && !linkedCommunity!.useTranslationKeys) {
      // categoryKey may already be a translation key for type mapping
      return linkedCommunity!.categoryKey;
    }
    return categoryDisplayKey ?? 'categories.$category';
  }

  factory CampaignModel.fromDonation(DonationModel donation) {
    final goal = donation.goal;
    final raised = donation.raised;

    return CampaignModel(
      id: 'd_${donation.id}',
      titleKey: donation.nameKey,
      category: _categorySlugFromDonation(donation.category),
      categoryDisplayKey: donation.category.titleKey,
      imageUrl: donation.image.isNotEmpty
          ? donation.image
          : 'https://picsum.photos/600/400?random=${donation.id}',
      goal: goal,
      raised: raised,
      progress: goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0,
      linkedDonation: donation,
    );
  }

  factory CampaignModel.fromCommunity(CommunityCampaignModel campaign) {
    return CampaignModel(
      id: 'c_${campaign.id}',
      titleKey: campaign.titleKey,
      category: _categorySlugFromCommunity(campaign.categoryKey),
      categoryDisplayKey: campaign.categoryKey,
      imageUrl: campaign.imageUrl,
      goal: campaign.goal,
      raised: campaign.raised,
      progress: campaign.progress,
      linkedCommunity: campaign,
    );
  }

  static String _categorySlugFromDonation(DonationCategory category) {
    switch (category) {
      case DonationCategory.medical:
        return 'patients';
      case DonationCategory.education:
        return 'education';
      case DonationCategory.orphans:
        return 'orphans';
    }
  }

  static String _categorySlugFromCommunity(String categoryKey) {
    final key = categoryKey.toLowerCase();
    if (key.contains('environmental') || key.contains('environment')) {
      return 'environment';
    }
    if (key.contains('education') || key.contains('educational')) {
      return 'education';
    }
    if (key.contains('humanitarian') ||
        key.contains('medical') ||
        key.contains('patient')) {
      return 'orphans';
    }
    return 'environment';
  }
  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final double goal = (json['goal'] as num).toDouble();
    final double raised = (json['raised'] as num).toDouble();

    return CampaignModel(
      id: json['id'].toString(),
      titleKey: json['title_key'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String,
      goal: goal,
      raised: raised,
      progress: goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title_key': titleKey,
    'category': category,
    'image_url': imageUrl,
    'goal': goal,
    'raised': raised,
  };

  CampaignModel copyWith({
    String? id,
    String? titleKey,
    String? category,
    String? categoryDisplayKey,
    String? imageUrl,
    double? progress,
    double? goal,
    double? raised,
    DonationModel? linkedDonation,
    CommunityCampaignModel? linkedCommunity,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      category: category ?? this.category,
      categoryDisplayKey: categoryDisplayKey ?? this.categoryDisplayKey,
      imageUrl: imageUrl ?? this.imageUrl,
      progress: progress ?? this.progress,
      goal: goal ?? this.goal,
      raised: raised ?? this.raised,
      linkedDonation: linkedDonation ?? this.linkedDonation,
      linkedCommunity: linkedCommunity ?? this.linkedCommunity,
    );
  }
}
