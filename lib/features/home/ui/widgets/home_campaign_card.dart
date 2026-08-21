import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../donations/data/models/donation_checkout_args.dart';
import '../../../donations/ui/utils/donation_flow_helper.dart';
import '../../data/models/campaign_model.dart';
import 'campaign_card.dart';

void openHomeCampaignDetails(BuildContext context, CampaignModel campaign) {
  if (campaign.linkedDonation != null) {
    context.push(AppRoutes.donationDetails, extra: campaign.linkedDonation);
  } else if (campaign.linkedCommunity != null) {
    context.push(
      AppRoutes.communityCampaignDetails,
      extra: campaign.linkedCommunity,
    );
  }
}

class HomeCampaignCard extends StatelessWidget {
  const HomeCampaignCard({
    super.key,
    required this.campaign,
    this.fullWidth = false,
  });

  final CampaignModel campaign;
  final bool fullWidth;

  void _donate(BuildContext context) {
    if (campaign.isFullyFunded) return;
    final community = campaign.linkedCommunity;
    if (community != null) {
      openDonateAmountScreen(
        context,
        donateArgsForCommunityCampaign(community),
      );
      return;
    }
    final linked = campaign.linkedDonation;
    openDonateAmountScreen(
      context,
      DonationCheckoutArgs(
        causeTitle: linked?.cardTitle ?? campaign.displayTitle,
        targetType: linked?.donateTargetType ?? DonationTargetType.association,
        targetId: linked != null && linked.id > 0 ? linked.id : null,
        caseCurrency: linked?.displayCurrency,
      ),
    );
  }

  void _sponsor(BuildContext context) {
    if (campaign.isFullyFunded) return;
    final linked = campaign.linkedDonation;
    if (linked == null) return;
    openDonateAmountScreen(context, linked.sponsorshipCheckoutArgs);
  }

  @override
  Widget build(BuildContext context) {
    return CampaignCard(
      title: campaign.linkedDonation?.cardTitle ?? campaign.displayTitle,
      category: campaign.categoryLabelKey.tr(),
      image: campaign.imageUrl,
      progress: campaign.progress,
      progressPercent: campaign.progressPercent,
      goal: campaign.formattedGoal(context.locale),
      donation: campaign.linkedDonation,
      fullWidth: fullWidth,
      onTap: () => openHomeCampaignDetails(context, campaign),
      onDonateTap: campaign.isFullyFunded ? null : () => _donate(context),
      onSponsorTap: campaign.isFullyFunded ? null : () => _sponsor(context),
    );
  }
}
