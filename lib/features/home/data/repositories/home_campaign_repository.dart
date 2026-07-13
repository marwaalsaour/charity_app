import '../../../campaigns/data/models/community_campaign_model.dart';
import '../../../campaigns/data/repositories/community_campaign_repository.dart';
import '../../../donations/data/models/donation_model.dart';
import '../../../donations/data/repositories/donation_repository.dart';
import '../models/campaign_model.dart';

class HomeCampaignRepository {
  HomeCampaignRepository({
    DonationRepository? donationRepository,
    CommunityCampaignRepository? communityCampaignRepository,
  })  : _donationRepository = donationRepository ?? DonationRepository(),
        _communityCampaignRepository =
            communityCampaignRepository ?? CommunityCampaignRepository();

  final DonationRepository _donationRepository;
  final CommunityCampaignRepository _communityCampaignRepository;

  Future<List<CampaignModel>> getRecentCampaigns() async {
    final results = await Future.wait([
      _donationRepository.getDonations(DonationCategory.education),
      _donationRepository.getDonations(DonationCategory.medical),
      _donationRepository.getDonations(DonationCategory.orphans),
      _communityCampaignRepository.getCampaigns(),
    ]);

    final donations = [
      ...results[0] as List<DonationModel>,
      ...results[1] as List<DonationModel>,
      ...results[2] as List<DonationModel>,
    ]..sort((a, b) => b.id.compareTo(a.id));

    final community = List<CommunityCampaignModel>.from(
      results[3] as List<CommunityCampaignModel>,
    )..sort((a, b) => b.id.compareTo(a.id));

    return [
      ...donations.map(CampaignModel.fromDonation),
      ...community.map(CampaignModel.fromCommunity),
    ];
  }
}
