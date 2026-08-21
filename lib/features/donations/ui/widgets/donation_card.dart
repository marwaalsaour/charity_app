import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/donation_model.dart';
import '../utils/donation_flow_helper.dart';
import 'case_verification_info.dart';
import 'donation_closed_box.dart';
import 'donation_cover_image.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({super.key, required this.donation});

  final DonationModel donation;

  static const double _imageHeight = 190;

  void _openDetails(BuildContext context) {
    context.push(AppRoutes.donationDetails, extra: donation);
  }

  void _openDonate(BuildContext context) {
    if (donation.isFullyFunded) return;
    openDonateAmountScreen(context, donation.checkoutArgs);
  }

  void _openSponsor(BuildContext context) {
    if (donation.isFullyFunded) return;
    openDonateAmountScreen(context, donation.sponsorshipCheckoutArgs);
  }

  @override
  Widget build(BuildContext context) {
    if (donation.category == DonationCategory.orphans) {
      return _OrphanCampaignStyleCard(
        donation: donation,
        onOpenDetails: () => _openDetails(context),
        onDonate: () => _openDonate(context),
        onSponsor: () => _openSponsor(context),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            onTap: () => _openDetails(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DonationCoverImage(donation: donation, height: _imageHeight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.cardTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        donation.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        donation.displayDescription,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      if (donation.hasVerificationInfo) ...[
                        const SizedBox(height: 10),
                        CaseVerificationInfo(donation: donation, compact: true),
                      ],
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: donation.progress,
                          minHeight: 6,
                          backgroundColor: ext.progressBg,
                          color: ext.progressFill,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${'raised'.tr()}: ${donation.formatRaised(context.locale)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ext.textSecondary,
                            ),
                          ),
                          Text(
                            '${(donation.progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentDark,
                            ),
                          ),
                          Text(
                            '${'goal'.tr()}: ${donation.formatGoal(context.locale)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ext.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          donation.isFullyFunded
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: DonationClosedBox(height: 48),
                )
              : Material(
                  color: cs.primary,
                  child: InkWell(
                    onTap: () => _openDonate(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'donate_now'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _OrphanCampaignStyleCard extends StatelessWidget {
  const _OrphanCampaignStyleCard({
    required this.donation,
    required this.onOpenDetails,
    required this.onDonate,
    required this.onSponsor,
  });

  final DonationModel donation;
  final VoidCallback onOpenDetails;
  final VoidCallback onDonate;
  final VoidCallback onSponsor;

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
            onTap: onOpenDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DonationCoverImage(donation: donation, height: 170),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.cardTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        donation.category.titleKey.tr().toUpperCase(),
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
                            '${'target'.tr()}: ${donation.formatGoal(context.locale)}',
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
                          value: donation.progress,
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
            child: donation.isFullyFunded
                ? const DonationClosedBox(height: 44)
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'donate'.tr(),
                          variant: ButtonVariant.outline,
                          height: 44,
                          onTap: onDonate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          label: 'sponsor_now'.tr(),
                          variant: ButtonVariant.accent,
                          height: 44,
                          onTap: onSponsor,
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
