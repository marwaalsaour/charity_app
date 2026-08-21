import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../data/models/benefit_request_models.dart';
import '../../logic/cubit/request_cubit.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_location_fields.dart';
import '../widgets/show_name_consent_tile.dart';

class MedicalRequestPage extends StatefulWidget {
  const MedicalRequestPage({super.key});

  @override
  State<MedicalRequestPage> createState() => _MedicalRequestPageState();
}

class _MedicalRequestPageState extends State<MedicalRequestPage> {
  final fullName = TextEditingController();
  final nationalId = TextEditingController();
  final contact = TextEditingController();
  final cost = TextEditingController();
  final description = TextEditingController();
  File? idPhoto;
  File? medicalReport;
  bool showBeneficiaryName = false;
  String _currency = 'USD';

  @override
  void dispose() {
    fullName.dispose();
    nationalId.dispose();
    contact.dispose();
    cost.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<RequestCubit>();
    final state = cubit.state;

    if (fullName.text.trim().isEmpty ||
        nationalId.text.trim().isEmpty ||
        description.text.trim().isEmpty ||
        state.selectedGovernorateId == null ||
        state.selectedCityId == null ||
        idPhoto == null ||
        medicalReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_fill_required'.tr())),
      );
      return;
    }

    final contactText = contact.text.trim();
    String? phone;
    String? email;
    var isSelf = true;

    if (contactText.isNotEmpty) {
      if (contactText.contains('@')) {
        isSelf = false;
        email = contactText;
      } else {
        final digits = contactText.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('request_invalid_contact'.tr())),
          );
          return;
        }
        isSelf = false;
        phone = digits;
      }
    }

    final ok = await cubit.submitBenefitRequest(
      BenefitRequestSubmitParams(
        kind: BenefitRequestKind.patient,
        fullName: fullName.text,
        nationalId: nationalId.text,
        governorateId: state.selectedGovernorateId!,
        regionId: state.selectedCityId!,
        description: description.text,
        isSelf: isSelf,
        phone: phone,
        email: email,
        requiredAmount: double.tryParse(cost.text),
        currency: _currency,
        medicalReport: medicalReport,
        nationalIdDocument: idPhoto,
        showBeneficiaryName: showBeneficiaryName,
      ),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_submitted_success'.tr())),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_localizeSubmitError(cubit.state.submitError)),
        ),
      );
    }
  }

  String _localizeSubmitError(String? error) {
    final message = error ?? 'request_submit_failed';
    // App keys are snake_case; Laravel messages have spaces — don't .tr() those.
    if (RegExp(r'^[a-z0-9_]+$').hasMatch(message)) {
      return message.tr();
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RequestCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('medical_request_title'.tr()),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          RequestFormCard(
            children: [
              CustomTextField(
                label: 'full_name'.tr(),
                hint: 'enter_full_name'.tr(),
                prefixIcon: Icons.person,
                controller: fullName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'national_id'.tr(),
                hint: 'enter_national_id'.tr(),
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                controller: nationalId,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'phone_or_email'.tr(),
                hint: 'phone_or_email_optional_hint'.tr(),
                prefixIcon: Icons.phone,
                controller: contact,
              ),
              const SizedBox(height: 16),
              const RequestLocationFields(),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'id_photo'.tr(),
                hint: 'tap_upload'.tr(),
                onImageSelected: (f) => setState(() => idPhoto = f),
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'medical_report'.tr(),
                hint: 'tap_upload'.tr(),
                onImageSelected: (f) => setState(() => medicalReport = f),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'description_need'.tr(),
                hint: 'describe_need'.tr(),
                maxLines: 4,
                controller: description,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'treatment_cost'.tr(),
                hint: 'cost_hint'.tr(),
                prefixIcon: Icons.attach_money,
                controller: cost,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Text(
                'request_currency_label'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WalletCurrencies.codes.map((code) {
                  final selected = _currency == code;
                  return ChoiceChip(
                    label: Text(code),
                    selected: selected,
                    onSelected: (_) => setState(() => _currency = code),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              ShowNameConsentTile(
                value: showBeneficiaryName,
                onChanged: (v) => setState(() => showBeneficiaryName = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'submit_request'.tr(),
            icon: Icons.favorite,
            isLoading: cubit.state.isLoading,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}
