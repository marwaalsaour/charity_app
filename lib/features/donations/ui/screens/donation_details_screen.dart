import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/utils/share_link_helper.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/donation_stats_enricher.dart';
import '../../data/models/donation_model.dart';
import '../../data/repositories/donation_repository.dart';
import '../utils/donation_flow_helper.dart';
import '../widgets/case_verification_info.dart';
import '../widgets/donation_closed_box.dart';
import '../widgets/donation_cover_image.dart';
import 'education_donation_details_screen.dart';
import 'medical_donation_details_screen.dart';

class DonationDetailsScreen extends StatefulWidget {
  final DonationModel donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  late DonationModel _donation;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _donation = widget.donation;
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    DonationModel base = widget.donation;
    final fresh = await DonationRepository().getById(widget.donation.id);
    if (fresh != null) base = fresh;
    final enriched = await enrichDonationWithLocalStats(base);
    if (!mounted) return;
    setState(() {
      _donation = enriched;
      _loading = false;
    });
  }

  Future<void> _onDonate() async {
    if (_donation.isFullyFunded) return;
    await openDonateAmountScreen(
      context,
      _donation.checkoutArgs,
    );
    if (mounted) await _refreshStats();
  }

  Future<void> _onSponsor() async {
    if (_donation.isFullyFunded) return;
    await openDonateAmountScreen(
      context,
      _donation.sponsorshipCheckoutArgs,
    );
    if (mounted) await _refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_donation.category) {
      case DonationCategory.education:
        return EducationDonationDetailsScreen(
          donation: _donation,
          onDonate: _onDonate,
        );
      case DonationCategory.medical:
        return MedicalDonationDetailsScreen(
          donation: _donation,
          onDonate: _onDonate,
        );
      case DonationCategory.orphans:
        return _StandardDonationDetailsScreen(
          donation: _donation,
          onDonate: _onDonate,
          onSponsor: _onSponsor,
        );
    }
  }
}

class _StandardDonationDetailsScreen extends StatelessWidget {
  const _StandardDonationDetailsScreen({
    required this.donation,
    required this.onDonate,
    this.onSponsor,
  });

  final DonationModel donation;
  final Future<void> Function() onDonate;
  final Future<void> Function()? onSponsor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AtaaAppBar(
        title: 'donation_details_title'.tr(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DonationCoverImage(donation: donation, height: 220),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CampaignProgressCard(donation: donation),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.category.titleKey.tr().toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ext.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          donation.cardTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (donation.displayTitle != donation.cardTitle) ...[
                          const SizedBox(height: 6),
                          Text(
                            donation.displayTitle,
                            style: TextStyle(
                              fontSize: 15,
                              color: ext.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.people_outline,
                                label: 'donor_count'.tr(),
                                value: '${donation.donorCount}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoTile(
                                icon: donation.residence != null &&
                                        donation.residence!.trim().isNotEmpty
                                    ? Icons.location_on_outlined
                                    : Icons.schedule_outlined,
                                label: donation.residence != null &&
                                        donation.residence!.trim().isNotEmpty
                                    ? 'location'.tr()
                                    : 'days_left'.tr(),
                                value: donation.residence != null &&
                                        donation.residence!.trim().isNotEmpty
                                    ? donation.residence!.trim()
                                    : '${donation.daysLeft}',
                              ),
                            ),
                          ],
                        ),
                        if (donation.hasVerificationInfo) ...[
                          const SizedBox(height: 16),
                          CaseVerificationInfo(donation: donation),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'the_story'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          donation.displayDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: ext.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
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
              child: donation.isFullyFunded
                  ? const DonationClosedBox()
                  : Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: 'donate_now'.tr(),
                            variant: ButtonVariant.primary,
                            icon: Icons.favorite_rounded,
                            height: 50,
                            onTap: onDonate,
                          ),
                        ),
                        if (onSponsor != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              label: 'sponsor_now'.tr(),
                              variant: ButtonVariant.accent,
                              icon: Icons.volunteer_activism_outlined,
                              height: 50,
                              onTap: onSponsor,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignProgressCard extends StatelessWidget {
  const _CampaignProgressCard({required this.donation});

  final DonationModel donation;

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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'raised_of_goal'.tr(
              namedArgs: {'goal': donation.formatGoal(context.locale)},
            ),
            style: TextStyle(fontSize: 12, color: ext.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                donation.formatRaised(context.locale),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${(donation.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
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
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ext.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
