import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../donations/data/models/orphan_sponsorship_model.dart';
import '../../../donations/data/orphan_sponsorship_service.dart';

class MySponsorshipsScreen extends StatefulWidget {
  const MySponsorshipsScreen({super.key});

  @override
  State<MySponsorshipsScreen> createState() => _MySponsorshipsScreenState();
}

class _MySponsorshipsScreenState extends State<MySponsorshipsScreen> {
  List<OrphanSponsorship> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await OrphanSponsorshipService.instance.listAll();
      all.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.startedAt.compareTo(a.startedAt);
      });
      if (!mounted) return;
      setState(() {
        _items = all;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.tr())),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(OrphanSponsorship item) async {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return Theme(
          data: theme,
          child: AlertDialog(
            backgroundColor: ext?.cardBackground ?? theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('sponsorship_cancel_title'.tr()),
            content: Text(
              'sponsorship_cancel_confirm_body'.tr(
                namedArgs: {'name': item.childName},
              ),
              style: TextStyle(
                height: 1.5,
                color: ext?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('confirm'.tr()),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;
    try {
      await OrphanSponsorshipService.instance.cancelSponsorship(item.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.tr())),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('sponsorship_cancelled_done'))),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AtaaAppBar(title: context.tr('my_sponsorships')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.tr('my_sponsorships_empty'),
                  key: ValueKey('sp_empty_${locale.languageCode}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: ext.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SponsorshipCard(
                  item: _items[index],
                  onCancel: () => _cancel(_items[index]),
                );
              },
            ),
    );
  }
}

class _SponsorshipCard extends StatelessWidget {
  const _SponsorshipCard({
    required this.item,
    required this.onCancel,
  });

  final OrphanSponsorship item;
  final VoidCallback onCancel;

  String _statusKey() {
    if (item.status == 'cancelled') return 'sponsorship_status_cancelled';
    if (item.isComplete) return 'sponsorship_status_completed';
    return 'sponsorship_status_active';
  }

  Color _statusColor(ColorScheme cs) {
    if (item.status == 'cancelled') return cs.error;
    if (item.isComplete) return AppColors.success;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final canManage = item.isActive && !item.isComplete;
    final statusColor = _statusColor(cs);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.child_care_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.childName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(_statusKey()),
                  key: ValueKey('${_statusKey()}_${locale.languageCode}'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'sponsorship_monthly_value',
              namedArgs: {
                'amount': _formatAmount(item.monthlyAmount),
                'currency': item.currency,
              },
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.totalMonths > 0
                ? context.tr(
                    'sponsorship_remaining_value',
                    namedArgs: {
                      'paid': '${item.paidMonths}',
                      'total': '${item.totalMonths}',
                    },
                  )
                : context.tr(
                    'sponsorship_next_charge',
                    namedArgs: {
                      'date': DateFormat.yMMMd(
                        locale.toString(),
                      ).format(item.nextChargeAt),
                    },
                  ),
            style: TextStyle(fontSize: 13, color: ext.textSecondary),
          ),
          if (canManage) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(context.tr('sponsorship_cancel')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatAmount(double amount) {
  if (!amount.isFinite) return '0';
  final whole = amount.truncateToDouble() == amount;
  return amount.toStringAsFixed(whole ? 0 : 2);
}
