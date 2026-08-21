import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/utils/share_link_helper.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/donation_model.dart';
import '../../data/models/donation_need_item.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../utils/donation_flow_helper.dart';
import '../widgets/case_verification_info.dart';
import '../widgets/donation_closed_box.dart';
import '../widgets/donation_cover_image.dart';

class EducationDonationDetailsScreen extends StatelessWidget {
  const EducationDonationDetailsScreen({
    super.key,
    required this.donation,
    this.onDonate,
  });

  final DonationModel donation;
  final Future<void> Function()? onDonate;

  @override
  Widget build(BuildContext context) {
    final percent = (donation.progress * 100).round();
    final goalText = donation.formatGoal(context.locale);

    return Scaffold(
      appBar: AtaaAppBar(
        title: 'donation_details_title'.tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ShareLinkHelper.copyCaseLink(context, donation),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DonationCoverImage(
                    donation: donation,
                    aspectRatio: 16 / 9,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _InfoCard(
                        donation: donation,
                        percent: percent,
                        goalText: goalText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (donation.hasVerificationInfo) ...[
                          CaseVerificationInfo(donation: donation),
                          const SizedBox(height: 16),
                        ],
                        _SectionHeader(title: 'the_story'.tr()),
                        const SizedBox(height: 10),
                        Text(
                          donation.displayDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .extension<AppThemeExtension>()!
                                .textSecondary,
                            height: 1.55,
                          ),
                        ),
                        if (donation.techTitleKey != null) ...[
                          const SizedBox(height: 20),
                          _TechRequirementsCard(donation: donation),
                        ],
                        if (donation.needs.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(title: 'needs_breakdown'.tr()),
                          const SizedBox(height: 12),
                          _NeedsBreakdownCard(
                            needs: donation.needs,
                            currency: donation.displayCurrency,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DonateBar(
            isClosed: donation.isFullyFunded,
            onTap: () async {
              if (donation.isFullyFunded) return;
              if (onDonate != null) {
                await onDonate!();
                return;
              }
              await openDonateAmountScreen(
                context,
                donation.checkoutArgs,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.donation,
    required this.percent,
    required this.goalText,
  });

  final DonationModel donation;
  final int percent;
  final String goalText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.cardTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation.displayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: ext.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (donation.isUrgent) const _UrgentBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: ext.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${donation.formatRaised(context.locale)} ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'raised_of_goal'.tr(namedArgs: {'goal': goalText}),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'percent_complete'.tr(namedArgs: {'percent': '$percent'}),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: donation.progress,
              minHeight: 8,
              backgroundColor: ext.progressBg,
              color: ext.progressFill,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 18,
                color: cs.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'donors_contributed'.tr(
                  namedArgs: {'count': '${donation.donorCount}'},
                ),
                style: TextStyle(fontSize: 12, color: ext.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'urgent_need'.tr(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TechRequirementsCard extends StatelessWidget {
  const _TechRequirementsCard({required this.donation});

  final DonationModel donation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                donation.techTitleKey!.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          if (donation.techDescKey != null) ...[
            const SizedBox(height: 8),
            Text(
              donation.techDescKey!.tr(),
              style: TextStyle(
                fontSize: 13,
                color: ext.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (donation.techTagKeys.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: donation.techTagKeys
                  .map(
                    (key) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: ext.inputFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            key.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeedsBreakdownCard extends StatelessWidget {
  const _NeedsBreakdownCard({required this.needs, required this.currency});

  final List<DonationNeedItem> needs;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < needs.length; i++) ...[
            if (i > 0) Divider(height: 20, color: ext.border),
            _NeedRow(need: needs[i], currency: currency),
          ],
        ],
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({required this.need, required this.currency});

  final DonationNeedItem need;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                need.titleKey.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                need.descKey.tr(),
                style: TextStyle(fontSize: 12, color: ext.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          WalletCurrencies.format(
            need.amount.toDouble(),
            currency,
            locale: context.locale,
          ),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: cs.primary,
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

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DonateBar extends StatelessWidget {
  const _DonateBar({required this.onTap, this.isClosed = false});

  final VoidCallback onTap;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
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
        child: isClosed
            ? const DonationClosedBox()
            : CustomButton(
                label: 'donate_now'.tr(),
                variant: ButtonVariant.accent,
                height: 54,
                onTap: onTap,
              ),
      ),
    );
  }
}
