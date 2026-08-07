import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../donations/data/models/donation_receipt_model.dart';
import '../../../donations/data/repositories/donation_api_repository.dart';
import '../../../donations/data/repositories/donation_receipt_repository.dart';
import '../../data/repositories/user_profile_repository.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final _localRepository = DonationReceiptRepository();
  final _apiRepository = DonationApiRepository();
  late Future<List<DonationReceiptModel>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  void _loadReceipts() {
    setState(() {
      _receiptsFuture = _fetchReceipts();
    });
  }

  Future<List<DonationReceiptModel>> _fetchReceipts() async {
    final profile = await UserProfileRepository().getProfile();
    final donorName = (profile != null && profile.hasName)
        ? profile.fullName
        : 'donor_mock_name'.tr();

    final local = await _localRepository.getReceipts();

    try {
      final remote = await _apiRepository.fetchMyDonations(donorName: donorName);
      if (remote.isEmpty) return local;

      final byId = <String, DonationReceiptModel>{};

      for (final r in remote) {
        byId[r.id] = DonationReceiptModel(
          id: r.id,
          donorName: r.donorName,
          recipientOrg: r.recipientOrg.tr(),
          causeTitle: r.causeTitle.tr(),
          amount: r.amount,
          currency: r.currency,
          date: r.date,
          agent: r.agent.tr(),
        );
      }

      // Keep locally-saved receipts (e.g. just after donate) and prefer
      // their cause titles when the API only returns a generic type.
      for (final r in local) {
        final remoteMatch = byId[r.id];
        if (remoteMatch == null) {
          byId[r.id] = r;
          continue;
        }

        final remoteTitle = remoteMatch.causeTitle.trim();
        final localTitle = r.causeTitle.trim();
        final remoteIsGeneric = remoteTitle.isEmpty ||
            remoteTitle == 'User' ||
            remoteTitle == 'recipient_org'.tr() ||
            remoteTitle == 'recipient_org';

        if (localTitle.isNotEmpty &&
            (remoteIsGeneric || localTitle.length > remoteTitle.length)) {
          byId[r.id] = DonationReceiptModel(
            id: remoteMatch.id,
            donorName: remoteMatch.donorName.isNotEmpty
                ? remoteMatch.donorName
                : r.donorName,
            recipientOrg: remoteMatch.recipientOrg,
            causeTitle: localTitle,
            amount: r.amount > 0 ? r.amount : remoteMatch.amount,
            currency: r.currency.isNotEmpty ? r.currency : remoteMatch.currency,
            date: r.date,
            agent: remoteMatch.agent,
          );
        }
      }

      final merged = byId.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      await _localRepository.replaceAll(merged);
      return merged;
    } catch (_) {
      return local;
    }
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
