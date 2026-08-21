import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../notifications/data/notification_helper.dart';
import '../../profile/data/repositories/user_profile_repository.dart';
import 'models/donation_checkout_args.dart';
import 'models/orphan_sponsorship_model.dart';
import 'repositories/donation_repository.dart';
import 'repositories/orphan_sponsorship_api_repository.dart';
import 'repositories/orphan_sponsorship_repository.dart';

class OrphanSponsorshipService {
  OrphanSponsorshipService._();

  static final instance = OrphanSponsorshipService._();
  static final _local = OrphanSponsorshipRepository();
  static final _api = OrphanSponsorshipApiRepository();

  Future<OrphanSponsorship> startSponsorship({
    required DonationCheckoutArgs args,
    required double monthlyAmount,
    required String currency,
    int totalMonths = 12,
  }) async {
    var orphanId = args.orphanId ?? 0;
    final requestId = args.targetId ?? 0;
    if (requestId > 0) {
      // Best-effort resolve; the backend's open-lists exclude orphans that
      // are already sponsored, so a failed resolve does NOT mean the id is
      // invalid — it can simply mean the sponsorship already went through
      // (or is being retried). Never fail locally here.
      final resolved =
          await DonationRepository().resolveOrphanIdForRequest(requestId);
      if (resolved != null && resolved > 0) {
        orphanId = resolved;
      } else if (orphanId <= 0) {
        // Fall back to the request id itself — the repository below already
        // knows how to retry with requestId if this turns out wrong.
        orphanId = requestId;
      }
    }
    if (orphanId <= 0) {
      throw const ApiException('sponsor_orphan_missing');
    }
    debugPrint(
      '[sponsor] requestId=$requestId resolvedOrphanId=$orphanId '
      'argsOrphanId=${args.orphanId}',
    );

    final created = await _api.sponsor(
      orphanId: orphanId,
      requestId: requestId > 0 ? requestId : null,
    );
    final title = args.causeTitle.trim();
    final named = created.copyWith(
      childName: title.isNotEmpty ? title : created.childName,
      monthlyAmount: monthlyAmount,
      currency: currency,
      totalMonths: totalMonths,
    );
    await _local.upsert(named);
    await AuthRepository().syncProfile();
    return named;
  }

  Future<List<OrphanSponsorship>> listAll() async {
    try {
      final remote = await _api.fetchMine();
      for (final item in remote) {
        await _local.upsert(item);
      }
      return remote;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) rethrow;
      final local = await _local.getAll();
      if (local.isNotEmpty) return local;
      rethrow;
    }
  }

  Future<void> continueSponsorship(String id) async {
    final item = await _local.getById(id);
    if (item == null) return;
    await _local.upsert(item.copyWith(needsDecision: false));
  }

  Future<void> cancelSponsorship(String id) async {
    final item = await _local.getById(id);
    final orphanId = item?.apiOrphanId ?? int.tryParse(id) ?? 0;
    if (orphanId > 0) {
      await _api.cancel(orphanId);
    }
    if (item != null) {
      await _local.upsert(
        item.copyWith(status: 'cancelled', needsDecision: false),
      );
    }
  }

  Future<OrphanSponsorship?> firstNeedingDecision() async {
    final active = await _local.getActive();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      item = await _local.getById(sponsorshipId);
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

  /// Server cron (`orphans:process-monthly-deductions`) charges due months.
  static Future<void> processDueAndPrompt(BuildContext context) async {
    await instance.listAll();
    await AuthRepository().syncProfile();
    if (!context.mounted) return;
    await handleDecision(context);
  }

  Future<void> notifyIfWalletEmpty(OrphanSponsorship item) async {
    final profile = await UserProfileRepository().getProfile();
    final wallet = profile?.walletBalances ?? const <String, double>{};
    final available = wallet[item.currency] ?? 0;
    if (available >= item.monthlyAmount) return;
    await NotificationHelper.notifySponsorshipWalletEmpty(
      childName: item.childName,
      sponsorshipId: item.id,
    );
    await _local.upsert(item.copyWith(needsDecision: true));
  }
}
