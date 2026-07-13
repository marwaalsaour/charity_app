import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/donation_checkout_args.dart';
import '../utils/donation_flow_helper.dart';

class DonateAmountScreen extends StatefulWidget {
  final DonationCheckoutArgs args;

  const DonateAmountScreen({super.key, required this.args});

  @override
  State<DonateAmountScreen> createState() => _DonateAmountScreenState();
}

class _DonateAmountScreenState extends State<DonateAmountScreen> {
  final _amountController = TextEditingController();
  String _currency = 'USD';
  bool _isSubmitting = false;

  static const _currencies = ['USD', 'SYP', 'EUR'];
  static const _quickAmounts = [50, 100, 250, 500];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('donate_amount_invalid'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await completeDonation(
      context: context,
      causeTitle: widget.args.causeTitle,
      amount: amount,
      currency: _currency,
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('donate_amount_title'.tr()),
      ),
      body: SingleChildScrollView(
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
                    style: TextStyle(fontSize: 13, color: ext.textSecondary),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _amountController,
              label: 'donate_amount_label'.tr(),
              hint: 'donate_amount_hint'.tr(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              prefixIcon: Icons.payments_outlined,
            ),
            const SizedBox(height: 16),
            Text(
              'donate_currency_label'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ext.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currency,
                  isExpanded: true,
                  dropdownColor: ext.cardBackground,
                  items: _currencies
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
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
                  onPressed: () => _amountController.text = '$value',
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: cs.onSurface),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'donate_confirm_btn'.tr(),
              variant: ButtonVariant.primary,
              isLoading: _isSubmitting,
              height: 55,
              onTap: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
