import 'package:easy_localization/easy_localization.dart';

class VolunteerActivityModel {
  final String id;
  final String campaignId;
  final String campaignTitleKey;
  final String locationKey;
  final int hours;
  final DateTime date;

  const VolunteerActivityModel({
    required this.id,
    required this.campaignId,
    required this.campaignTitleKey,
    required this.locationKey,
    required this.hours,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaign_id': campaignId,
    'campaign_title_key': campaignTitleKey,
    'location_key': locationKey,
    'hours': hours,
    'date': date.toIso8601String(),
  };

  factory VolunteerActivityModel.fromJson(Map<String, dynamic> json) {
    return VolunteerActivityModel(
      id: json['id']?.toString() ?? '',
      campaignId: json['campaign_id']?.toString() ?? '0',
      campaignTitleKey: json['campaign_title_key']?.toString() ?? '',
      locationKey: json['location_key']?.toString() ?? '',
      hours: json['hours'] is num
          ? (json['hours'] as num).round()
          : int.tryParse('${json['hours']}') ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CampaignVolunteerSummary {
  final String campaignId;
  final String titleKey;
  final String locationKey;
  final int totalHours;
  final DateTime lastDate;
  final bool useTranslationKeys;
  /// pending | approved | rejected | ''
  final String status;
  final String type;
  final String titleAr;
  final String titleEn;
  final String locationAr;
  final String locationEn;

  const CampaignVolunteerSummary({
    required this.campaignId,
    required this.titleKey,
    required this.locationKey,
    required this.totalHours,
    required this.lastDate,
    this.useTranslationKeys = true,
    this.status = '',
    this.type = '',
    this.titleAr = '',
    this.titleEn = '',
    this.locationAr = '',
    this.locationEn = '',
  });

  String localizedTitle(String languageCode) {
    if (useTranslationKeys && titleKey.isNotEmpty) return titleKey.tr();
    final preferred = languageCode == 'ar' ? titleAr : titleEn;
    final resolved = _resolveText(
      preferred.isNotEmpty ? preferred : titleKey,
    );
    if (resolved.isNotEmpty) return resolved;
    return 'campaign_unnamed'.tr(namedArgs: {'id': campaignId});
  }

  String localizedLocation(String languageCode) {
    if (useTranslationKeys && locationKey.isNotEmpty) return locationKey.tr();
    final preferred = languageCode == 'ar' ? locationAr : locationEn;
    return _resolveText(preferred.isNotEmpty ? preferred : locationKey);
  }

  String get typeLabel {
    switch (type.toLowerCase().trim()) {
      case 'educational':
      case 'education':
        return 'community_campaigns.cat_education'.tr();
      case 'medical':
      case 'patients':
        return 'categories.patients'.tr();
      case 'humanitarian':
        return 'community_campaigns.cat_humanitarian'.tr();
      case 'environmental':
      case 'environment':
        return 'community_campaigns.cat_environmental'.tr();
      default:
        return '';
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'volunteer_status_pending'.tr();
      case 'approved':
        return 'volunteer_status_approved'.tr();
      case 'rejected':
        return 'volunteer_status_rejected'.tr();
      default:
        return '';
    }
  }

  static String _resolveText(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    if (_isTranslationKey(text)) return text.tr();
    return text;
  }

  static bool _isTranslationKey(String value) {
    return !value.contains(' ') &&
        value.contains('.') &&
        RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value);
  }
}
