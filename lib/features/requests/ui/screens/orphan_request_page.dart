import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../data/models/benefit_request_models.dart';
import '../../logic/cubit/request_cubit.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_location_fields.dart';
import '../widgets/show_name_consent_tile.dart';

class OrphanRequestPage extends StatefulWidget {
  const OrphanRequestPage({super.key});

  @override
  State<OrphanRequestPage> createState() => _OrphanRequestPageState();
}

class _OrphanRequestPageState extends State<OrphanRequestPage> {
  final name = TextEditingController();
  final nationalId = TextEditingController();
  final phone = TextEditingController();
  final description = TextEditingController();
  File? familyBooklet;
  File? deathCertificate;
  bool showBeneficiaryName = false;

  @override
  void dispose() {
    name.dispose();
    nationalId.dispose();
    phone.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<RequestCubit>();
    final state = cubit.state;

    if (name.text.trim().isEmpty ||
        nationalId.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        description.text.trim().isEmpty ||
        state.selectedGovernorateId == null ||
        state.selectedCityId == null ||
        familyBooklet == null ||
        deathCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_fill_required'.tr())),
      );
      return;
    }

    final phoneDigits = phone.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_invalid_contact'.tr())),
      );
      return;
    }

    final ok = await cubit.submitBenefitRequest(
      BenefitRequestSubmitParams(
        kind: BenefitRequestKind.orphan,
        fullName: name.text,
        nationalId: nationalId.text,
        governorateId: state.selectedGovernorateId!,
        regionId: state.selectedCityId!,
        description: description.text,
        phone: phoneDigits,
        familyBooklet: familyBooklet,
        fatherDeathCertificate: deathCertificate,
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
        title: Text('orphan_request_title'.tr()),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          RequestFormCard(
            children: [
              CustomTextField(
                label: 'child_full_name'.tr(),
                hint: 'enter_full_name'.tr(),
                prefixIcon: Icons.person,
                controller: name,
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
              const RequestLocationFields(),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'phone'.tr(),
                hint: 'phone_hint'.tr(),
                prefixIcon: Icons.phone,
                controller: phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'description_need'.tr(),
                hint: 'describe_need'.tr(),
                maxLines: 4,
                controller: description,
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'family_booklet'.tr(),
                hint: 'tap_upload'.tr(),
                onImageSelected: (f) => setState(() => familyBooklet = f),
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'death_certificate'.tr(),
                hint: 'tap_upload'.tr(),
                onImageSelected: (f) => setState(() => deathCertificate = f),
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
