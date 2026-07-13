import 'package:flutter/material.dart';

import 'donation_need_item.dart';

enum DonationCategory { education, medical, orphans }

extension DonationCategoryX on DonationCategory {
  String get titleKey {
    switch (this) {
      case DonationCategory.education:
        return 'education_title';
      case DonationCategory.medical:
        return 'medical_title';
      case DonationCategory.orphans:
        return 'orphans_title';
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case DonationCategory.education:
        return Icons.school_outlined;
      case DonationCategory.medical:
        return Icons.medical_services_outlined;
      case DonationCategory.orphans:
        return Icons.child_care_outlined;
    }
  }
}

class DonationModel {
  final int id;
  final String nameKey;
  final String titleKey;
  final String descriptionKey;
  final DonationCategory category;
  final double raised;
  final double goal;
  final String image;
  final bool isUrgent;
  final String? techTitleKey;
  final String? techDescKey;
  final List<String> techTagKeys;
  final String? hospitalKey;
  final String? doctorKey;
  final String? storyKey;
  final List<DonationNeedItem> needs;

  const DonationModel({
    required this.id,
    required this.nameKey,
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.raised,
    required this.goal,
    required this.image,
    this.isUrgent = false,
    this.techTitleKey,
    this.techDescKey,
    this.techTagKeys = const [],
    this.hospitalKey,
    this.doctorKey,
    this.storyKey,
    this.needs = const [],
  });

  double get progress =>
      goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

  int get donorCount => (raised / 30).round().clamp(8, 999);

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] as int,
      nameKey: json['name_key'] as String,
      titleKey: json['title_key'] as String,
      descriptionKey: json['description_key'] as String,
      category: DonationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DonationCategory.medical,
      ),
      raised: (json['raised'] as num).toDouble(),
      goal: (json['goal'] as num).toDouble(),
      image: json['image'] as String? ?? '',
      isUrgent: json['is_urgent'] as bool? ?? false,
    );
  }
}
