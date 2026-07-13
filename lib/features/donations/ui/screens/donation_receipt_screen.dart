import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/donation_receipt_model.dart';

class DonationReceiptScreen extends StatelessWidget {
  final DonationReceiptModel receipt;

  const DonationReceiptScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;
    final dateText = DateFormat.yMMMd(context.locale.languageCode).format(
      receipt.date,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('donation_receipt_title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ext.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: cs.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'donation_receipt_success'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ReceiptRow(
                    label: 'receipt_donor'.tr(),
                    value: receipt.donorName,
                  ),
                  _ReceiptRow(
                    label: 'receipt_recipient'.tr(),
                    value: receipt.recipientOrg,
                  ),
                  _ReceiptRow(
                    label: 'receipt_cause'.tr(),
                    value: receipt.causeTitle,
                  ),
                  _ReceiptRow(
                    label: 'receipt_amount'.tr(),
                    value: receipt.formattedAmount,
                    highlight: true,
                  ),
                  _ReceiptRow(
                    label: 'receipt_date'.tr(),
                    value: dateText,
                  ),
                  _ReceiptRow(
                    label: 'receipt_agent'.tr(),
                    value: receipt.agent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'receipt_back_home'.tr(),
              variant: ButtonVariant.primary,
              onTap: () => context.go(AppRoutes.donorHome),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: ext.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: highlight ? 16 : 14,
                color: highlight ? cs.primary : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
