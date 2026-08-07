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
    final accepted = await _donationRepository.getAllOpenAccepted();
    final community = await _communityCampaignRepository.getCampaigns();

    final donations = <DonationModel>[];
    if (accepted != null && accepted.isNotEmpty) {
      // Real approved cases for donors — first cards in "Recent campaigns".
      donations.addAll(accepted);
    } else if (accepted == null) {
      // API unavailable and no cache: keep demo mocks so home is not blank.
      final mocks = await Future.wait([
        _donationRepository.getDonations(DonationCategory.education),
        _donationRepository.getDonations(DonationCategory.medical),
        _donationRepository.getDonations(DonationCategory.orphans),
      ]);
      for (final list in mocks) {
        donations.addAll(list);
      }
    }

    donations.sort((a, b) => b.id.compareTo(a.id));

    final communitySorted = List<CommunityCampaignModel>.from(community)
      ..sort((a, b) => b.id.compareTo(a.id));

    return [
      ...donations.map(CampaignModel.fromDonation),
      ...communitySorted.map(CampaignModel.fromCommunity),
    ];
  }
}
