import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../auth/data/repositories/auth_repository.dart';
import '../../notifications/data/notification_helper.dart';
import '../../profile/data/repositories/user_profile_repository.dart';
import 'models/donation_checkout_args.dart';
import 'models/orphan_sponsorship_model.dart';
import 'repositories/donation_api_repository.dart';
import 'repositories/orphan_sponsorship_repository.dart';

class OrphanSponsorshipService {
  OrphanSponsorshipService._();

  static final instance = OrphanSponsorshipService._();
  static final _repository = OrphanSponsorshipRepository();

  Future<void> startSponsorship({
    required DonationCheckoutArgs args,
    required double amount,
    required String currency,
    required int months,
  }) async {
    final now = DateTime.now();
    final sponsorship = OrphanSponsorship(
      id: 'sp_${now.millisecondsSinceEpoch}',
      requestId: args.targetId,
      childName: args.causeTitle,
      monthlyAmount: amount,
      currency: currency,
      totalMonths: months,
      paidMonths: 1,
      startedAt: now,
      nextChargeAt: DateTime(now.year, now.month + 1, now.day),
    );
    await _repository.upsert(sponsorship);
    await notifyIfWalletEmpty(sponsorship);
  }

  Future<void> continueSponsorship(String id) async {
    final item = await _repository.getById(id);
    if (item == null) return;
    await _repository.upsert(item.copyWith(needsDecision: false));
  }

  Future<void> cancelSponsorship(String id) async {
    final item = await _repository.getById(id);
    if (item == null) return;
    await _repository.upsert(
      item.copyWith(status: 'cancelled', needsDecision: false),
    );
  }

  Future<void> updateMonthlyAmount(String id, double amount) async {
    final item = await _repository.getById(id);
    if (item == null || amount <= 0) return;
    await _repository.upsert(item.copyWith(monthlyAmount: amount));
  }

  Future<List<OrphanSponsorship>> listAll() => _repository.getAll();

  Future<void> processDueCharges() async {
    final active = await _repository.getActive();
    if (active.isEmpty) return;

    final profile = await AuthRepository().syncProfile() ??
        await UserProfileRepository().getProfile();
    final balances = profile?.walletBalances ?? const <String, double>{};
    final now = DateTime.now();

    for (final item in active) {
      if (item.nextChargeAt.isAfter(now)) continue;

      final available = balances[item.currency] ?? 0;
      if (available < item.monthlyAmount) {
        await _markEmpty(item);
        continue;
      }

      try {
        await DonationApiRepository().donate(
          args: DonationCheckoutArgs(
            causeTitle: item.childName,
            targetType: item.requestId != null && item.requestId! > 0
                ? DonationTargetType.request
                : DonationTargetType.association,
            targetId: item.requestId,
          ),
          amount: item.monthlyAmount,
          currency: item.currency,
          donorName: profile?.fullName ?? 'donor_mock_name'.tr(),
        );
        final paid = item.paidMonths + 1;
        final next = DateTime(now.year, now.month + 1, now.day);
        await _repository.upsert(
          item.copyWith(
            paidMonths: paid,
            nextChargeAt: next,
            status: paid >= item.totalMonths ? 'completed' : 'active',
            needsDecision: false,
          ),
        );
        await AuthRepository().syncProfile();
      } catch (_) {
        await _markEmpty(item);
      }
    }
  }

  Future<void> notifyIfWalletEmpty(
    OrphanSponsorship item, {
    Map<String, double>? balances,
  }) async {
    Map<String, double> wallet = balances ?? const {};
    if (balances == null) {
      final profile = await UserProfileRepository().getProfile();
      wallet = profile?.walletBalances ?? const {};
    }
    final available = wallet[item.currency] ?? 0;
    if (available >= item.monthlyAmount) {
      if (item.needsDecision) {
        await _repository.upsert(item.copyWith(needsDecision: false));
      }
      return;
    }
    await _markEmpty(item);
  }

  Future<void> _markEmpty(OrphanSponsorship item) async {
    if (!item.needsDecision) {
      await NotificationHelper.notifySponsorshipWalletEmpty(
        childName: item.childName,
        sponsorshipId: item.id,
      );
    }
    await _repository.upsert(item.copyWith(needsDecision: true));
  }

  Future<OrphanSponsorship?> firstNeedingDecision() async {
    final active = await _repository.getActive();
    for (final item in active) {
      if (item.needsDecision) return item;
    }
    return null;
  }

  static Future<bool?> showDecisionDialog(
    BuildContext context,
    OrphanSponsorship sponsorship,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('sponsorship_wallet_empty_title'.tr()),
          content: Text(
            'sponsorship_wallet_empty_body'.tr(
              namedArgs: {'name': sponsorship.childName},
            ),
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('sponsorship_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('sponsorship_continue'.tr()),
            ),
          ],
        );
      },
    );
  }

  static Future<void> handleDecision(
    BuildContext context, {
    String? sponsorshipId,
  }) async {
    OrphanSponsorship? item;
    if (sponsorshipId != null && sponsorshipId.isNotEmpty) {
      item = await _repository.getById(sponsorshipId);
      if (item != null && !item.needsDecision) return;
    }
    item ??= await instance.firstNeedingDecision();
    if (item == null || !context.mounted) return;

    final keep = await showDecisionDialog(context, item);
    if (keep == true) {
      await instance.continueSponsorship(item.id);
    } else if (keep == false) {
      await instance.cancelSponsorship(item.id);
    }
  }

  static Future<void> processDueAndPrompt(BuildContext context) async {
    await instance.processDueCharges();
    if (!context.mounted) return;
    await handleDecision(context);
  }
}
