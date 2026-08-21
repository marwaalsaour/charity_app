import 'package:easy_localization/easy_localization.dart';

import '../../../../core/network/api_constants.dart';

class CommunityCampaignModel {
  final String id;
  final String titleKey;
  final String categoryKey;
  final String storyKey;
  final String locationKey;
  final String imageUrl;
  final double raised;
  final double goal;
  final int volunteerCount;
  final bool useTranslationKeys;
  final bool acceptsDonations;
  final bool acceptsVolunteers;
  final String status;

  const CommunityCampaignModel({
    required this.id,
    required this.titleKey,
    required this.categoryKey,
    required this.storyKey,
    required this.locationKey,
    required this.imageUrl,
    required this.raised,
    required this.goal,
    required this.volunteerCount,
    this.useTranslationKeys = true,
    this.acceptsDonations = true,
    this.acceptsVolunteers = true,
    this.status = 'open',
  });

  double get progress => goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progress * 100).round();

  bool get isFullyFunded =>
      status == 'closed' || status == 'completed' || (goal > 0 && raised >= goal);

  String get formattedGoal => '\$${goal.toInt()}';

  String get formattedRaised => '\$${raised.toInt()}';

  int get apiId => int.tryParse(id) ?? 0;

  String get displayTitle =>
      useTranslationKeys ? titleKey.tr() : titleKey;

  String get displayCategory => categoryKey.tr();

  String get displayStory =>
      useTranslationKeys ? storyKey.tr() : storyKey;

  String get displayLocation =>
      useTranslationKeys ? locationKey.tr() : locationKey;

  factory CommunityCampaignModel.fromApi(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';
    final type = json['type']?.toString() ?? '';
    final media = json['media'];
    String imageUrl = 'https://picsum.photos/600/400?random=$id';
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        final raw = first['image']?.toString();
        final resolved = ApiConstants.storageUrl(raw);
        if (resolved != null && resolved.isNotEmpty) {
          imageUrl = resolved;
        }
      }
    }

    final needed = _toDouble(json['amount_needed']);
    final collected = _toDouble(json['amount_collected']);
    final volunteersJoined = _toInt(json['volunteers_joined']) ??
        _toInt(json['approved_volunteers_count']) ??
        0;

    final acceptsDonations = json['accepts_donations'] == true ||
        json['participation_type']?.toString() == 'donation_only' ||
        json['participation_type']?.toString() == 'donation_and_volunteer' ||
        needed > 0;
    final acceptsVolunteers = json['accepts_volunteers'] == true ||
        json['participation_type']?.toString() == 'volunteer_only' ||
        json['participation_type']?.toString() == 'donation_and_volunteer';

    final description = json['description']?.toString().trim();
    final title = json['title']?.toString().trim().isNotEmpty == true
        ? json['title'].toString().trim()
        : 'Campaign #$id';

    return CommunityCampaignModel(
      id: id,
      titleKey: title,
      categoryKey: _categoryLabel(type),
      storyKey: (description != null && description.isNotEmpty)
          ? description
          : title,
      locationKey: json['status']?.toString() ?? 'open',
      imageUrl: imageUrl,
      raised: collected,
      goal: needed > 0 ? needed : collected,
      volunteerCount: volunteersJoined,
      useTranslationKeys: false,
      acceptsDonations: acceptsDonations,
      acceptsVolunteers: acceptsVolunteers,
      status: json['status']?.toString() ?? 'open',
    );
  }

  static String _categoryLabel(String type) {
    switch (type) {
      case 'educational':
        return 'community_campaigns.cat_education';
      case 'medical':
        return 'categories.patients';
      case 'humanitarian':
        return 'community_campaigns.cat_humanitarian';
      case 'environmental':
        return 'community_campaigns.cat_environmental';
      default:
        return type.isEmpty ? 'community_campaigns.cat_humanitarian' : type;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
