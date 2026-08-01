import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../donations/data/models/donation_receipt_model.dart';
import '../../../donations/data/repositories/donation_receipt_repository.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final _repository = DonationReceiptRepository();
  late Future<List<DonationReceiptModel>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  void _loadReceipts() {
    setState(() {
      _receiptsFuture = _repository.getReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('my_donations'.tr()),
      ),
      body: FutureBuilder<List<DonationReceiptModel>>(
        future: _receiptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final receipts = snapshot.data ?? [];

          if (receipts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 56,
                      color: ext.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_receipts_yet'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: ext.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: receipts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              final date = DateFormat.yMMMd(
                context.locale.languageCode,
              ).format(receipt.date);

              return Material(
                color: ext.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  onTap: () => context.push(
                    '${AppRoutes.donationReceipt}?from=profile',
                    extra: receipt,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: ext.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cs.primary.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.receipt_long,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receipt.causeTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ext.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          receipt.formattedAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: ext.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
