import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../data/models/donation_checkout_args.dart';
import '../../data/orphan_sponsorship_service.dart';
import '../utils/donation_flow_helper.dart';

class DonateAmountScreen extends StatefulWidget {
  final DonationCheckoutArgs args;

  const DonateAmountScreen({super.key, required this.args});

  @override
  State<DonateAmountScreen> createState() => _DonateAmountScreenState();
}

class _DonateAmountScreenState extends State<DonateAmountScreen> {
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  bool _loadingWallet = true;
  Map<String, double> _balances = WalletCurrencies.empty;
  String _currency = 'USD';
  int _sponsorshipMonths = 12;

  static const _quickAmounts = [50, 100, 250, 500];
  static const _monthOptions = [1, 3, 6, 12];

  List<String> get _fundedCodes => WalletCurrencies.codes
      .where((code) => (_balances[code] ?? 0) > 0)
      .toList();

  double get _available => _balances[_currency] ?? 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    final remote = await AuthRepository().syncProfile();
    final profile = remote ?? await UserProfileRepository().getProfile();
    if (!mounted) return;
    final wallet = profile?.walletBalances ?? WalletCurrencies.empty;
    final funded = WalletCurrencies.codes
        .where((code) => (wallet[code] ?? 0) > 0)
        .toList();
    final caseCurrency = WalletCurrencies.normalizeCode(
          widget.args.caseCurrency,
        ) ??
        'USD';
    setState(() {
      _balances = wallet;
      if (funded.contains(caseCurrency)) {
        _currency = caseCurrency;
      } else {
        _currency = funded.isNotEmpty ? funded.first : caseCurrency;
      }
      _loadingWallet = false;
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('donate_amount_invalid'.tr())));
      return;
    }

    if (_fundedCodes.isEmpty || amount > _available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('donate_insufficient_balance'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final receipt = await completeDonation(
      context: context,
      args: widget.args.copyWith(sponsorshipMonths: _sponsorshipMonths),
      amount: amount,
      currency: _currency,
    );
    if (receipt != null && widget.args.isOrphanSponsorship) {
      await OrphanSponsorshipService.instance.startSponsorship(
        args: widget.args.copyWith(sponsorshipMonths: _sponsorshipMonths),
        amount: amount,
        currency: _currency,
        months: _sponsorshipMonths,
      );
      if (mounted) context.go(AppRoutes.mySponsorships);
      return;
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AtaaAppBar(
        title: widget.args.isOrphanSponsorship
            ? 'sponsor_now'.tr()
            : 'donate_amount_title'.tr(),
      ),
      body: _loadingWallet
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ext.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: ext.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'donate_for'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: ext.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.args.causeTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (widget.args.caseCurrency != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'donate_case_currency'.tr(
                              namedArgs: {
                                'currency': widget.args.caseCurrency!,
                              },
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: ext.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'donate_currency_label'.tr(),
                    style: TextStyle(fontSize: 13, color: ext.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WalletCurrencies.codes.map((code) {
                      final amount = _balances[code] ?? 0;
                      final enabled = amount > 0;
                      final selected = _currency == code && enabled;
                      return ChoiceChip(
                        label: Text(
                          '${WalletCurrencies.format(amount, code, locale: context.locale)}  $code',
                        ),
                        selected: selected,
                        onSelected: enabled
                            ? (_) => setState(() => _currency = code)
                            : null,
                        selectedColor: cs.primary.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: enabled ? cs.onSurface : ext.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fundedCodes.isEmpty
                        ? 'donate_no_wallet_balance'.tr()
                        : 'donate_available_balance'.tr(
                            namedArgs: {
                              'amount': WalletCurrencies.formatAmount(
                                _available,
                                context.locale,
                              ),
                              'currency': _currency,
                            },
                          ),
                    style: TextStyle(
                      fontSize: 13,
                      color: _fundedCodes.isEmpty
                          ? Theme.of(context).colorScheme.error
                          : ext.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.args.isOrphanSponsorship) ...[
                    Text(
                      'sponsor_months_label'.tr(),
                      style: TextStyle(fontSize: 13, color: ext.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _monthOptions.map((months) {
                        final selected = _sponsorshipMonths == months;
                        return ChoiceChip(
                          label: Text(
                            'sponsor_months_value'.tr(
                              namedArgs: {'months': '$months'},
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _sponsorshipMonths = months),
                          selectedColor: cs.primary.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: cs.onSurface,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  CustomTextField(
                    controller: _amountController,
                    label: widget.args.isOrphanSponsorship
                        ? 'sponsor_amount_label'.tr()
                        : 'donate_amount_label'.tr(),
                    hint: 'donate_amount_hint'.tr(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    prefixIcon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'donate_quick_amounts'.tr(),
                    style: TextStyle(fontSize: 13, color: ext.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts.map((value) {
                      return ActionChip(
                        label: Text('$value $_currency'),
                        onPressed: _fundedCodes.isEmpty
                            ? null
                            : () => _amountController.text = '$value',
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: cs.onSurface),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: widget.args.isOrphanSponsorship
                        ? 'sponsor_confirm_btn'.tr()
                        : 'donate_confirm_btn'.tr(),
                    variant: ButtonVariant.primary,
                    isLoading: _isSubmitting,
                    height: 55,
                    onTap: _isSubmitting || _fundedCodes.isEmpty
                        ? null
                        : _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
