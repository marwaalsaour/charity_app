import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/models/donation_receipt_model.dart';
import '../../data/repositories/donation_receipt_repository.dart';

void openDonateAmountScreen(BuildContext context, DonationCheckoutArgs args) {
  context.push(AppRoutes.donateAmount, extra: args);
}

Future<bool> showDonationConfirmDialog(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        backgroundColor: theme.extension<AppThemeExtension>()!.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('donate_confirm_title'.tr()),
        content: Text(
          'donate_confirm_message'.tr(),
          style: TextStyle(
            height: 1.5,
            color: theme.extension<AppThemeExtension>()!.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr()),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<DonationReceiptModel?> completeDonation({
  required BuildContext context,
  required String causeTitle,
  required double amount,
  required String currency,
}) async {
  final confirmed = await showDonationConfirmDialog(context);
  if (!confirmed || !context.mounted) return null;

  final receipt = DonationReceiptModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    donorName: 'donor_mock_name'.tr(),
    recipientOrg: 'recipient_org'.tr(),
    causeTitle: causeTitle,
    amount: amount,
    currency: currency,
    date: DateTime.now(),
    agent: 'receipt_agent_value'.tr(),
  );

  await DonationReceiptRepository().saveReceipt(receipt);
  if (!context.mounted) return null;

  context.push(AppRoutes.donationReceipt, extra: receipt);
  return receipt;
}
