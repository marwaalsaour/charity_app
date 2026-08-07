import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/utils/share_link_helper.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/models/donation_model.dart';
import '../../data/models/donation_need_item.dart';
import '../utils/donation_flow_helper.dart';
import '../widgets/case_verification_info.dart';
import '../widgets/donation_cover_image.dart';

class MedicalDonationDetailsScreen extends StatelessWidget {
  const MedicalDonationDetailsScreen({
    super.key,
    required this.donation,
    this.onDonate,
  });

  final DonationModel donation;
  final Future<void> Function()? onDonate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (donation.progress * 100).round();
    final goalText = '\$${donation.goal.toInt()}';
    final daysLeft = donation.daysLeft;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: Text(
          'medical_details_title'.tr(),
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
                        daysLeft: daysLeft,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryBadge(label: donation.titleKey.tr()),
                        if (donation.hasVerificationInfo) ...[
                          const SizedBox(height: 12),
                          CaseVerificationInfo(donation: donation),
                        ],
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'the_story'.tr()),
                        const SizedBox(height: 10),
                        Text(
                          (donation.storyKey ?? donation.descriptionKey).tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .extension<AppThemeExtension>()!
                                .textSecondary,
                            height: 1.55,
                          ),
                        ),
                        if (donation.hospitalKey != null ||
                            donation.doctorKey != null) ...[
                          const SizedBox(height: 20),
                          _CareInfoCard(donation: donation),
                        ],
                        if (donation.needs.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(title: 'medical_needs'.tr()),
                          const SizedBox(height: 12),
                          _MedicalNeedsList(needs: donation.needs),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DonateBar(
            onTap: () async {
              if (onDonate != null) {
                await onDonate!();
                return;
              }
              await openDonateAmountScreen(
                context,
                DonationCheckoutArgs(
                  causeTitle: donation.cardTitle,
                  targetType: donation.donateTargetType,
                  targetId:
                      donation.donateTargetType == DonationTargetType.request
                          ? donation.id
                          : null,
                ),
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
    required this.daysLeft,
  });

  final DonationModel donation;
  final int percent;
  final String goalText;
  final int daysLeft;

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
                child: Text(
                  donation.displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (donation.isUrgent) const _UrgentBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${donation.raised.toInt()}',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '${donation.donorCount}',
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

class _CareInfoCard extends StatelessWidget {
  const _CareInfoCard({required this.donation});

  final DonationModel donation;

  @override
  Widget build(BuildContext context) {
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
        children: [
          if (donation.hospitalKey != null)
            _CareRow(
              icon: Icons.local_hospital_outlined,
              label: 'hospital_label'.tr(),
              value: donation.hospitalKey!.tr(),
            ),
          if (donation.hospitalKey != null && donation.doctorKey != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: ext.border),
            ),
          if (donation.doctorKey != null)
            _CareRow(
              icon: Icons.person_outline,
              label: 'doctor_label'.tr(),
              value: donation.doctorKey!.tr(),
            ),
        ],
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ext.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: ext.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicalNeedsList extends StatelessWidget {
  const _MedicalNeedsList({required this.needs});

  final List<DonationNeedItem> needs;

  static const _icons = [
    Icons.medication_outlined,
    Icons.biotech_outlined,
    Icons.healing_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < needs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MedicalNeedTile(
            need: needs[i],
            icon: _icons[i % _icons.length],
          ),
        ],
      ],
    );
  }
}

class _MedicalNeedTile extends StatelessWidget {
  const _MedicalNeedTile({required this.need, required this.icon});

  final DonationNeedItem need;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ext.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: cs.primary),
          ),
          const SizedBox(width: 12),
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
                if (need.descKey.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    need.descKey.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: ext.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\$${need.amount.toInt()}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Row(
      children: [
        Container(
          width: 24,
          height: 2,
          color: ext.border,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _DonateBar extends StatelessWidget {
  const _DonateBar({required this.onTap});

  final VoidCallback onTap;

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
        child: CustomButton(
          label: 'donate_now'.tr(),
          variant: ButtonVariant.accent,
          icon: Icons.favorite_rounded,
          height: 54,
          onTap: onTap,
        ),
      ),
    );
  }
}
