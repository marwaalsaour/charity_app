import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../home/data/repositories/home_stats_repository.dart';
import '../../../home/logic/home_cubit.dart';
import '../../../notifications/data/notification_helper.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/case_donation_stats_cache.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/models/donation_receipt_model.dart';
import '../../data/repositories/donation_api_repository.dart';
import '../../data/repositories/donation_receipt_repository.dart';

Future<void> openDonateAmountScreen(
  BuildContext context,
  DonationCheckoutArgs args,
) {
  return context.push(AppRoutes.donateAmount, extra: args);
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
  required DonationCheckoutArgs args,
  required double amount,
  required String currency,
}) async {
  final confirmed = await showDonationConfirmDialog(context);
  if (!confirmed || !context.mounted) return null;

  try {
    final profile = await UserProfileRepository().getProfile();
    final donorName = (profile != null && profile.hasName)
        ? profile.fullName
        : 'donor_mock_name'.tr();

    final receipt = await DonationApiRepository().donate(
      args: args,
      amount: amount,
      currency: currency,
      donorName: donorName,
    );

    // Keep a local cache for offline viewing + refresh wallet from server.
    await DonationReceiptRepository().saveReceipt(
      DonationReceiptModel(
        id: receipt.id,
        donorName: receipt.donorName,
        recipientOrg: receipt.recipientOrg.tr(),
        causeTitle: receipt.causeTitle,
        amount: receipt.amount,
        currency: receipt.currency,
        date: receipt.date,
        agent: receipt.agent.tr(),
      ),
    );
    await AuthRepository().syncProfile();

    // Each successful donation increases home + case donor counters by 1.
    await HomeStatsRepository().recordDonationSuccess();
    if (args.targetId != null && args.targetId! > 0) {
      await CaseDonationStatsCache.recordDonation(
        requestId: args.targetId!,
        amountUsd: amount,
      );
    }
    if (context.mounted) {
      try {
        final homeCubit = context.read<HomeCubit>();
        await homeCubit.refreshStats();
        await homeCubit.refresh();
      } catch (_) {
        // HomeCubit may be unavailable outside the donor shell.
      }
    }

    await NotificationHelper.notifyDonationSuccess(
      amount: amount,
      currency: currency,
      causeTitle: args.causeTitle,
    );
    if (!context.mounted) return null;

    final localized = DonationReceiptModel(
      id: receipt.id,
      donorName: receipt.donorName,
      recipientOrg: receipt.recipientOrg.tr(),
      causeTitle: receipt.causeTitle,
      amount: receipt.amount,
      currency: receipt.currency,
      date: receipt.date,
      agent: receipt.agent.tr(),
    );

    context.push(AppRoutes.donationReceipt, extra: localized);
    return localized;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.tr())),
      );
    }
    return null;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('donate_error_generic'.tr())),
      );
    }
    return null;
  }
}
