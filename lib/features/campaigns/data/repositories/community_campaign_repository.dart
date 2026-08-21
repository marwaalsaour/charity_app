import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/community_campaign_model.dart';

/// Community campaigns against GitHub Ataa-Project APIs:
/// GET /campaigns, GET /campaigns/{id}, fallback GET /dashboard/top-campaigns
class CommunityCampaignRepository {
  CommunityCampaignRepository({Dio? dio})
      : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<CommunityCampaignModel>> getCampaigns() async {
    final fromList = await _tryGetCampaigns();
    if (fromList != null && fromList.isNotEmpty) return fromList;

    final fromTop = await _tryTopCampaigns();
    if (fromTop != null && fromTop.isNotEmpty) return fromTop;

    return _mockCampaigns();
  }

  Future<CommunityCampaignModel?> getById(String id) async {
    try {
      final response = await _dio.get('/campaigns/$id');
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final campaign = data['campaign'];
      if (campaign is! Map) return null;
      return CommunityCampaignModel.fromApi(
        Map<String, dynamic>.from(campaign),
      );
    } catch (_) {
      // Legacy public details path (older Azure builds).
      try {
        final response = await _dio.get('/getCampaignDetails/$id');
        final data = response.data;
        if (data is! Map || data['success'] != true) return null;
        final campaign = data['campaign'];
        if (campaign is! Map) return null;
        return CommunityCampaignModel.fromApi(
          Map<String, dynamic>.from(campaign),
        );
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<CommunityCampaignModel>?> _tryGetCampaigns() async {
    try {
      final response = await _dio.get(
        '/campaigns',
        queryParameters: {'status': 'open', 'per_page': 50},
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final list = _extractList(data['campaigns']);
      if (list == null) return null;

      return list
          .whereType<Map>()
          .map(
            (item) => CommunityCampaignModel.fromApi(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<CommunityCampaignModel>?> _tryTopCampaigns() async {
    try {
      final response = await _dio.get('/dashboard/top-campaigns');
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final raw = data['top_campaigns'];
      if (raw is! List || raw.isEmpty) return null;

      final results = <CommunityCampaignModel>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        if (id == null) continue;

        final detailed = await getById(id);
        results.add(
          detailed ??
              CommunityCampaignModel.fromApi(
                Map<String, dynamic>.from(item),
              ),
        );
      }
      return results;
    } catch (_) {
      return null;
    }
  }

  List? _extractList(dynamic campaigns) {
    if (campaigns is List) return campaigns;
    if (campaigns is Map && campaigns['data'] is List) {
      return campaigns['data'] as List;
    }
    return null;
  }

  List<CommunityCampaignModel> _mockCampaigns() {
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
    ];
  }
}
