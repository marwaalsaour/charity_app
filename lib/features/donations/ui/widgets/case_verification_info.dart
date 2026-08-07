import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../data/models/donation_model.dart';

/// Compact verification lines shown on case cards / details.
class CaseVerificationInfo extends StatelessWidget {
  const CaseVerificationInfo({
    super.key,
    required this.donation,
    this.compact = false,
  });

  final DonationModel donation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!donation.hasVerificationInfo) return const SizedBox.shrink();

    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    if (donation.showBeneficiaryName &&
        donation.beneficiaryName != null &&
        donation.beneficiaryName!.trim().isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: Icons.person_outline,
          label: 'case_beneficiary_name'.tr(),
          value: donation.beneficiaryName!.trim(),
          compact: compact,
        ),
      );
    } else if (!compact) {
      rows.add(
        _InfoRow(
          icon: Icons.privacy_tip_outlined,
          label: 'case_beneficiary_name'.tr(),
          value: 'case_name_hidden'.tr(),
          compact: compact,
        ),
      );
    }

    if (donation.residence != null && donation.residence!.trim().isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'case_residence'.tr(),
          value: donation.residence!.trim(),
          compact: compact,
        ),
      );
    }

    if (donation.institution != null &&
        donation.institution!.trim().isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: donation.category == DonationCategory.education
              ? Icons.school_outlined
              : Icons.apartment_outlined,
          label: donation.category == DonationCategory.education
              ? 'case_institution'.tr()
              : 'case_institution'.tr(),
          value: donation.institution!.trim(),
          compact: compact,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ext.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: compact ? 4 : 8),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 14 : 16, color: cs.primary),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: ext.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
