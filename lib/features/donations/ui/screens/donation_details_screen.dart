import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/utils/share_link_helper.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/models/donation_model.dart';
import '../utils/donation_flow_helper.dart';
import '../widgets/donation_cover_image.dart';
import 'education_donation_details_screen.dart';
import 'medical_donation_details_screen.dart';

class DonationDetailsScreen extends StatelessWidget {
  final DonationModel donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    switch (donation.category) {
      case DonationCategory.education:
        return EducationDonationDetailsScreen(donation: donation);
      case DonationCategory.medical:
        return MedicalDonationDetailsScreen(donation: donation);
      case DonationCategory.orphans:
        return _StandardDonationDetailsScreen(donation: donation);
    }
  }
}

class _StandardDonationDetailsScreen extends StatelessWidget {
  const _StandardDonationDetailsScreen({required this.donation});

  final DonationModel donation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;
    final percent = (donation.progress * 100).round();
    final donors = (donation.raised / 30).round().clamp(12, 999);
    final daysLeft = (35 - donation.id * 4).clamp(5, 60);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: Text(
          'donation_details_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareLinkHelper.copyCaseLink(context, donation),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DonationCoverImage(
                    donation: donation,
                    aspectRatio: 16 / 10,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  const SizedBox(height: 16),
                  _CategoryBadge(label: donation.category.titleKey.tr()),
                  const SizedBox(height: 12),
                  Text(
                    donation.nameKey.tr(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    donation.titleKey.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: ext.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProgressCard(
                    raised: donation.raised,
                    goal: donation.goal,
                    percent: percent,
                    donors: donors,
                    daysLeft: daysLeft,
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'the_story'.tr()),
                  const SizedBox(height: 12),
                  Text(
                    donation.descriptionKey.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: ext.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomButton(
                label: 'donate_now'.tr(),
                variant: ButtonVariant.accent,
                icon: Icons.favorite_rounded,
                height: 54,
                onTap: () => openDonateAmountScreen(
                  context,
                  DonationCheckoutArgs(causeTitle: donation.nameKey.tr()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: cs.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.raised,
    required this.goal,
    required this.percent,
    required this.donors,
    required this.daysLeft,
  });

  final double raised;
  final double goal;
  final int percent;
  final int donors;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;
    final goalText = '\$${goal.toInt()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${raised.toInt()}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'raised_of_goal'.tr(namedArgs: {'goal': goalText}),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ext.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: ext.progressBg,
              color: ext.progressFill,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '$donors',
                  label: 'donor_count'.tr(),
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: '$daysLeft',
                  label: 'days_left'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ext.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
