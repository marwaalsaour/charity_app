import '../models/community_campaign_model.dart';

class CommunityCampaignRepository {
  Future<List<CommunityCampaignModel>> getCampaigns() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      CommunityCampaignModel(
        id: 'c1',
        titleKey: 'community_campaigns.plant_trees_title',
        categoryKey: 'community_campaigns.cat_environmental',
        storyKey: 'community_campaigns.plant_trees_story',
        locationKey: 'community_campaigns.plant_trees_location',
        imageUrl: 'https://picsum.photos/600/400?random=51',
        raised: 4800,
        goal: 8000,
        volunteerCount: 124,
      ),
      CommunityCampaignModel(
        id: 'c2',
        titleKey: 'community_campaigns.village_school_title',
        categoryKey: 'community_campaigns.cat_education',
        storyKey: 'community_campaigns.village_school_story',
        locationKey: 'community_campaigns.village_school_location',
        imageUrl: 'https://picsum.photos/600/400?random=52',
        raised: 37500,
        goal: 50000,
        volunteerCount: 89,
      ),
      CommunityCampaignModel(
        id: 'c3',
        titleKey: 'community_campaigns.ramadan_baskets_title',
        categoryKey: 'community_campaigns.cat_humanitarian',
        storyKey: 'community_campaigns.ramadan_baskets_story',
        locationKey: 'community_campaigns.ramadan_baskets_location',
        imageUrl: 'https://picsum.photos/600/400?random=53',
        raised: 4500,
        goal: 15000,
        volunteerCount: 210,
      ),
      CommunityCampaignModel(
        id: 'c4',
        titleKey: 'community_campaigns.beach_cleanup_title',
        categoryKey: 'community_campaigns.cat_environmental',
        storyKey: 'community_campaigns.beach_cleanup_story',
        locationKey: 'community_campaigns.beach_cleanup_location',
        imageUrl: 'https://picsum.photos/600/400?random=54',
        raised: 2700,
        goal: 6000,
        volunteerCount: 67,
      ),
    ];
  }
}
