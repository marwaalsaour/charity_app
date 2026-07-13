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
  });

  double get progress => goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progress * 100).round();

  String get formattedGoal => '\$${goal.toInt()}';

  String get formattedRaised => '\$${raised.toInt()}';
}
