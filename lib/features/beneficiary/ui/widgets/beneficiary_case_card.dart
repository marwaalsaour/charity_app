import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../../requests/data/models/benefit_request_models.dart';

class BeneficiaryCaseCard extends StatelessWidget {
  const BeneficiaryCaseCard({
    super.key,
    required this.item,
    this.compact = false,
  });

  final BenefitRequestItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = item.isFullyFunded
        ? AppColors.success
        : item.isApproved
            ? AppColors.primary
            : item.isRejected
                ? AppColors.error
                : AppColors.accentDark;
    final statusLabel = item.isFullyFunded
        ? 'beneficiary_status_completed'.tr()
        : item.isApproved
            ? 'beneficiary_status_published'.tr()
            : item.isRejected
                ? 'beneficiary_status_rejected'.tr()
                : 'beneficiary_status_pending'.tr();
    final currency = WalletCurrencies.normalizeCode(item.currency) ?? 'USD';
    final raisedText = WalletCurrencies.format(
      item.donatedAmount,
      currency,
      locale: context.locale,
    );
    final goalText = WalletCurrencies.format(
      item.requiredAmount,
      currency,
      locale: context.locale,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isFullyFunded
              ? AppColors.success.withValues(alpha: 0.45)
              : ext.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isFullyFunded
                      ? Icons.verified_outlined
                      : item.isApproved
                          ? Icons.campaign_outlined
                          : item.isRejected
                              ? Icons.cancel_outlined
                              : Icons.pending_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat.yMMMd(context.locale.languageCode)
                    .format(item.createdAt),
                style: TextStyle(fontSize: 11, color: ext.textSecondary),
              ),
            ],
          ),
          if (!compact &&
              item.description != null &&
              item.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: ext.textSecondary),
            ),
          ],
          if (item.isApproved) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'progress'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ext.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'percent_complete'.tr(
                    namedArgs: {'percent': '${item.progressPercent}'},
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: item.isFullyFunded ? AppColors.success : cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 8,
                backgroundColor: ext.progressBg,
                valueColor: AlwaysStoppedAnimation(
                  item.isFullyFunded
                      ? AppColors.success
                      : AppColors.progressFill,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.hasFundingTarget
                        ? 'beneficiary_raised_of_goal'.tr(
                            namedArgs: {
                              'raised': raisedText,
                              'goal': goalText,
                            },
                          )
                        : raisedText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
          if (item.isFullyFunded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'beneficiary_amount_transferred'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
