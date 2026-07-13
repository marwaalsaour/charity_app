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
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      campaignTitleKey: json['campaign_title_key'] as String,
      locationKey: json['location_key'] as String,
      hours: json['hours'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class CampaignVolunteerSummary {
  final String campaignId;
  final String titleKey;
  final String locationKey;
  final int totalHours;
  final DateTime lastDate;

  const CampaignVolunteerSummary({
    required this.campaignId,
    required this.titleKey,
    required this.locationKey,
    required this.totalHours,
    required this.lastDate,
  });
}
