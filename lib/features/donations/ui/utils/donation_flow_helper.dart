import 'dart:async';

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
import '../../../campaigns/data/models/community_campaign_model.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/models/donation_receipt_model.dart';
import '../../data/orphan_sponsorship_service.dart';
import '../../data/repositories/donation_api_repository.dart';
import '../../data/repositories/donation_receipt_repository.dart';

DonationCheckoutArgs donateArgsForCommunityCampaign(
  CommunityCampaignModel campaign,
) {
  final id = campaign.apiId;
  if (id > 0) {
    return DonationCheckoutArgs(
      causeTitle: campaign.displayTitle,
      targetType: DonationTargetType.campaign,
      targetId: id,
    );
  }
  return DonationCheckoutArgs(
    causeTitle: campaign.displayTitle,
    targetType: DonationTargetType.association,
  );
}

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

String localizedApiMessage(String message) {
  if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(message)) {
    return message.tr();
  }
  return 'donate_error_generic'.tr();
}

Future<bool> showSponsorshipConfirmDialog(
  BuildContext context, {
  required double amount,
  required String currency,
  int months = 12,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        backgroundColor: theme.extension<AppThemeExtension>()!.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('sponsor_confirm_title'.tr()),
        content: Text(
          'sponsor_confirm_message'.tr(
            namedArgs: {
              'amount': amount.toStringAsFixed(
                amount.truncateToDouble() == amount ? 0 : 2,
              ),
              'currency': currency,
              'months': '$months',
            },
          ),
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
            child: Text('sponsor_confirm_btn'.tr()),
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
  final bool confirmed;
  if (args.isOrphanSponsorship) {
    confirmed = await showSponsorshipConfirmDialog(
      context,
      amount: amount,
      currency: currency,
      months: args.totalMonths ?? 12,
    );
  } else {
    confirmed = await showDonationConfirmDialog(context);
  }
  if (!context.mounted || !confirmed) return null;

  try {
    final profile = await UserProfileRepository().getProfile();
    final donorName = (profile != null && profile.hasName)
        ? profile.fullName
        : 'donor_mock_name'.tr();

    final DonationReceiptModel receipt;
    if (args.isOrphanSponsorship) {
      final sponsorship = await OrphanSponsorshipService.instance
          .startSponsorship(
            args: args,
            monthlyAmount: amount,
            currency: currency,
            totalMonths: args.totalMonths ?? 12,
          );
      receipt = DonationReceiptModel(
        id: sponsorship.id,
        donorName: donorName,
        recipientOrg: 'recipient_org',
        causeTitle: args.causeTitle,
        amount: amount,
        currency: currency,
        date: DateTime.now(),
        agent: 'receipt_agent_value',
      );
    } else {
      receipt = await DonationApiRepository().donate(
        args: args,
        amount: amount,
        currency: currency,
        donorName: donorName,
      );
    }

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

    await DonationReceiptRepository().saveReceipt(localized);

    if (args.targetId != null && args.targetId! > 0) {
      await CaseDonationStatsCache.recordDonation(
        requestId: args.targetId!,
        amount: amount,
        currency: currency,
        caseCurrency: args.caseCurrency ?? currency,
      );
      if (receipt.caseDonorsCount != null || receipt.caseRaisedAmount != null) {
        await CaseDonationStatsCache.mergeFromServer(
          requestId: args.targetId!,
          donorsCount: receipt.caseDonorsCount ?? 0,
          raised: receipt.caseRaisedAmount ?? 0,
          caseCurrency: args.caseCurrency,
        );
      }
    }

    if (!context.mounted) return localized;
    if (!args.isOrphanSponsorship) {
      context.push(AppRoutes.donationReceipt, extra: localized);
    }

    unawaited(
      _afterDonationSideEffects(
        context: context,
        args: args,
        amount: amount,
        currency: currency,
      ),
    );
    return localized;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizedApiMessage(e.message))));
    }
    return null;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('donate_error_generic'.tr())));
    }
    return null;
  }
}

Future<void> _afterDonationSideEffects({
  required BuildContext context,
  required DonationCheckoutArgs args,
  required double amount,
  required String currency,
}) async {
  try {
    await AuthRepository().syncProfile();
    await HomeStatsRepository().recordDonationSuccess();
    if (context.mounted) {
      try {
        await context.read<HomeCubit>().refreshStats();
      } catch (_) {}
    }
    await NotificationHelper.notifyDonationSuccess(
      amount: amount,
      currency: currency,
      causeTitle: args.causeTitle,
    );
  } catch (_) {}
}
