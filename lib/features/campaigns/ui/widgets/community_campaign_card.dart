import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/community_campaign_model.dart';

class CommunityCampaignCard extends StatelessWidget {
  const CommunityCampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    required this.onVolunteer,
    required this.onDonate,
  });

  final CommunityCampaignModel campaign;
  final VoidCallback? onTap;
  final VoidCallback onVolunteer;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  campaign.imageUrl,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    color: cs.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.campaign_outlined, color: cs.primary, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.titleKey.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        campaign.categoryKey.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ext.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'progress'.tr().toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ext.textSecondary,
                            ),
                          ),
                          Text(
                            '${'target'.tr()}: ${campaign.formattedGoal}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ext.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: campaign.progress,
                          minHeight: 6,
                          backgroundColor: ext.progressBg,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'volunteer'.tr(),
                    variant: ButtonVariant.accent,
                    height: 44,
                    onTap: onVolunteer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    label: 'donate'.tr(),
                    variant: ButtonVariant.outline,
                    height: 44,
                    onTap: onDonate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
