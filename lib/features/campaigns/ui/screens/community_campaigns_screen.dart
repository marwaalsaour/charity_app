import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../donations/data/models/donation_checkout_args.dart';
import '../../../donations/ui/utils/donation_flow_helper.dart';
import '../../data/models/community_campaign_model.dart';
import '../../data/repositories/community_campaign_repository.dart';
import '../widgets/community_campaign_card.dart';

class CommunityCampaignsScreen extends StatelessWidget {
  const CommunityCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('community_campaigns.screen_title'.tr()),
      ),
      body: FutureBuilder<List<CommunityCampaignModel>>(
        future: CommunityCampaignRepository().getCampaigns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final campaigns = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'community_campaigns.ongoing_impact'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ext.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'community_campaigns.active_title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              ...campaigns.map(
                (campaign) => CommunityCampaignCard(
                  campaign: campaign,
                  onTap: () => context.push(
                    AppRoutes.communityCampaignDetails,
                    extra: campaign,
                  ),
                  onVolunteer: () => context.push(
                    AppRoutes.fieldVolunteer,
                    extra: campaign,
                  ),
                  onDonate: () => openDonateAmountScreen(
                    context,
                    DonationCheckoutArgs(
                      causeTitle: campaign.titleKey.tr(),
                      targetType: DonationTargetType.association,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
