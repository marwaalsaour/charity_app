import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../logic/cubit/request_cubit.dart';
import '../../logic/states/request_state.dart';
import '../widgets/request_form_card.dart';

class EducationRequestPage extends StatelessWidget {
  EducationRequestPage({super.key});

  final uniName = TextEditingController();
  final uniMotherName = TextEditingController();
  final uniYear = TextEditingController();
  final uniDesc = TextEditingController();

  final schoolName = TextEditingController();
  final schoolMotherName = TextEditingController();
  final schoolGrade = TextEditingController();
  final schoolTitle = TextEditingController();
  final schoolAddress = TextEditingController();
  final schoolDesc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RequestCubit>();
    final state = cubit.state;

    return Scaffold(
      appBar: AppBar(title: Text('education_request_title'.tr())),
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
            onTap: () {
              if (state.educationType == 0) {
                cubit.submitForm(
                  type: 'education',
                  name: uniName.text,
                  contact: '',
                  address: '',
                  note: uniDesc.text,
                  grade: uniYear.text,
                  institution: 'University',
                );
              } else {
                cubit.submitForm(
                  type: 'education',
                  name: schoolName.text,
                  contact: '',
                  address: schoolAddress.text,
                  note: schoolDesc.text,
                  grade: schoolGrade.text,
                  institution: schoolTitle.text,
                );
              }
            },
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
        label: 'mother_name'.tr(),
        hint: 'enter_mother_name'.tr(),
        prefixIcon: Icons.woman,
        controller: uniMotherName,
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
      ),
      const SizedBox(height: 16),
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
        label: 'mother_name'.tr(),
        hint: 'enter_mother_name'.tr(),
        prefixIcon: Icons.woman,
        controller: schoolMotherName,
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
      CustomTextField(
        label: 'address'.tr(),
        hint: 'address_hint'.tr(),
        prefixIcon: Icons.location_on,
        controller: schoolAddress,
      ),
      const SizedBox(height: 16),
      ImageUploadBox(
        label: 'family_book_photo'.tr(),
        hint: 'tap_upload'.tr(),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'description_need'.tr(),
        hint: 'describe_need'.tr(),
        maxLines: 4,
        controller: schoolDesc,
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
              ? cs.primary.withValues(alpha: 0.1)
              : ext.cardBackground,
          border: Border.all(
            color: selected ? cs.primary : ext.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? cs.primary : ext.textSecondary),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? cs.primary : cs.onSurface,
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
          color: selected ? cs.primary : ext.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : ext.border,
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
