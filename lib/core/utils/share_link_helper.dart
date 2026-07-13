import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/campaigns/data/models/community_campaign_model.dart';
import '../../features/donations/data/models/donation_model.dart';

class ShareLinkHelper {
  ShareLinkHelper._();

  static const String baseUrl = 'https://ataa-charity.app';

  static String caseLink(int id) => '$baseUrl/case/$id';

  static String campaignLink(String id) => '$baseUrl/campaign/$id';

  static Future<void> copyCaseLink(
    BuildContext context,
    DonationModel donation,
  ) {
    return copyLink(
      context,
      caseLink(donation.id),
      title: donation.nameKey.tr(),
    );
  }

  static Future<void> copyCampaignLink(
    BuildContext context,
    CommunityCampaignModel campaign,
  ) {
    return copyLink(
      context,
      campaignLink(campaign.id),
      title: campaign.titleKey.tr(),
    );
  }

  static Future<void> copyLink(
    BuildContext context,
    String link, {
    String? title,
  }) async {
    final text = title != null ? '$title\n$link' : link;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('link_copied'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
