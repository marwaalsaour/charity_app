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
import '../../data/models/benefit_request_models.dart';
import '../../logic/cubit/request_cubit.dart';
import '../../logic/states/request_state.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_location_fields.dart';
import '../widgets/show_name_consent_tile.dart';

class EducationRequestPage extends StatefulWidget {
  const EducationRequestPage({super.key});

  @override
  State<EducationRequestPage> createState() => _EducationRequestPageState();
}

class _EducationRequestPageState extends State<EducationRequestPage> {
  final uniName = TextEditingController();
  final uniNationalId = TextEditingController();
  final uniUniversity = TextEditingController();
  final uniYear = TextEditingController();
  final uniDesc = TextEditingController();

  final schoolName = TextEditingController();
  final schoolNationalId = TextEditingController();
  final schoolGrade = TextEditingController();
  final schoolTitle = TextEditingController();
  final schoolDesc = TextEditingController();

  File? universityIdPhoto;
  File? familyBookPhoto;
  bool showBeneficiaryName = false;

  @override
  void dispose() {
    uniName.dispose();
    uniNationalId.dispose();
    uniUniversity.dispose();
    uniYear.dispose();
    uniDesc.dispose();
    schoolName.dispose();
    schoolNationalId.dispose();
    schoolGrade.dispose();
    schoolTitle.dispose();
    schoolDesc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<RequestCubit>();
    final state = cubit.state;

    if (state.selectedGovernorateId == null || state.selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_fill_required'.tr())),
      );
      return;
    }

    final bool ok;
    if (state.educationType == 0) {
      if (uniName.text.trim().isEmpty ||
          uniNationalId.text.trim().isEmpty ||
          uniYear.text.trim().isEmpty ||
          uniDesc.text.trim().isEmpty ||
          universityIdPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('request_fill_required'.tr())),
        );
        return;
      }
      ok = await cubit.submitBenefitRequest(
        BenefitRequestSubmitParams(
          kind: BenefitRequestKind.university,
          fullName: uniName.text,
          nationalId: uniNationalId.text,
          governorateId: state.selectedGovernorateId!,
          regionId: state.selectedCityId!,
          description: uniDesc.text,
          academicYear: uniYear.text,
          universityName: uniUniversity.text,
          supportType: cubit.supportTypeApiValue,
          universityIdPhoto: universityIdPhoto,
          showBeneficiaryName: showBeneficiaryName,
        ),
      );
    } else {
      if (schoolName.text.trim().isEmpty ||
          schoolNationalId.text.trim().isEmpty ||
          schoolGrade.text.trim().isEmpty ||
          schoolTitle.text.trim().isEmpty ||
          schoolDesc.text.trim().isEmpty ||
          familyBookPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('request_fill_required'.tr())),
        );
        return;
      }
      ok = await cubit.submitBenefitRequest(
        BenefitRequestSubmitParams(
          kind: BenefitRequestKind.school,
          fullName: schoolName.text,
          nationalId: schoolNationalId.text,
          governorateId: state.selectedGovernorateId!,
          regionId: state.selectedCityId!,
          description: schoolDesc.text,
          academicGrade: schoolGrade.text,
          schoolName: schoolTitle.text,
          familyBookPhoto: familyBookPhoto,
          showBeneficiaryName: showBeneficiaryName,
        ),
      );
    }

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
    final state = cubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('education_request_title'.tr()),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              Expanded(
                child: _typeCard(
                  context,
                  'university_student'.tr(),
                  Icons.account_balance,
                  state.educationType == 0,
                  () => cubit.changeEducationType(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _typeCard(
                  context,
                  'school_student'.tr(),
                  Icons.school,
                  state.educationType == 1,
                  () => cubit.changeEducationType(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RequestFormCard(
            children: [
              if (state.educationType == 0)
                ..._universityFields(context, state)
              else
                ..._schoolFields(),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'submit_request'.tr(),
            icon: Icons.school,
            isLoading: state.isLoading,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  List<Widget> _universityFields(BuildContext context, RequestState state) {
    final cubit = context.read<RequestCubit>();

    return [
      CustomTextField(
        label: 'full_name'.tr(),
        hint: 'enter_full_name'.tr(),
        prefixIcon: Icons.person,
        controller: uniName,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'national_id'.tr(),
        hint: 'enter_national_id'.tr(),
        prefixIcon: Icons.badge_outlined,
        keyboardType: TextInputType.number,
        controller: uniNationalId,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'university_name'.tr(),
        hint: 'university_name_hint'.tr(),
        prefixIcon: Icons.account_balance,
        controller: uniUniversity,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'academic_year'.tr(),
        hint: 'academic_year_hint'.tr(),
        prefixIcon: Icons.calendar_month,
        controller: uniYear,
      ),
      const SizedBox(height: 16),
      ImageUploadBox(
        label: 'university_id_photo'.tr(),
        hint: 'tap_upload'.tr(),
        onImageSelected: (f) => setState(() => universityIdPhoto = f),
      ),
      const SizedBox(height: 16),
      const RequestLocationFields(),
      const SizedBox(height: 16),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'support_type'.tr(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _chip(
            context,
            'laptop_support'.tr(),
            state.supportType == 0,
            () => cubit.changeSupportType(0),
          ),
          _chip(
            context,
            'tuition_assistance'.tr(),
            state.supportType == 1,
            () => cubit.changeSupportType(1),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'description_need'.tr(),
        hint: 'describe_need'.tr(),
        maxLines: 4,
        controller: uniDesc,
      ),
      const SizedBox(height: 8),
      ShowNameConsentTile(
        value: showBeneficiaryName,
        onChanged: (v) => setState(() => showBeneficiaryName = v),
      ),
    ];
  }

  List<Widget> _schoolFields() {
    return [
      CustomTextField(
        label: 'student_full_name'.tr(),
        hint: 'student_name_hint'.tr(),
        prefixIcon: Icons.person,
        controller: schoolName,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'national_id'.tr(),
        hint: 'enter_national_id'.tr(),
        prefixIcon: Icons.badge_outlined,
        keyboardType: TextInputType.number,
        controller: schoolNationalId,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'academic_grade'.tr(),
        hint: 'grade_hint'.tr(),
        prefixIcon: Icons.school,
        controller: schoolGrade,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'school_name'.tr(),
        hint: 'school_name_hint'.tr(),
        prefixIcon: Icons.business,
        controller: schoolTitle,
      ),
      const SizedBox(height: 16),
      const RequestLocationFields(),
      const SizedBox(height: 16),
      ImageUploadBox(
        label: 'family_book_photo'.tr(),
        hint: 'tap_upload'.tr(),
        onImageSelected: (f) => setState(() => familyBookPhoto = f),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'description_need'.tr(),
        hint: 'describe_need'.tr(),
        maxLines: 4,
        controller: schoolDesc,
      ),
      const SizedBox(height: 8),
      ShowNameConsentTile(
        value: showBeneficiaryName,
        onChanged: (v) => setState(() => showBeneficiaryName = v),
      ),
    ];
  }

  Widget _typeCard(
    BuildContext context,
    String title,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 96,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : ext.cardBackground,
          border: Border.all(
            color: selected ? AppColors.primary : ext.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : ext.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : ext.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : ext.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
