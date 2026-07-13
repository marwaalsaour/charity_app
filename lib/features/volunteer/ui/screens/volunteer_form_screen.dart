import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/document_upload_box.dart';
import '../../data/volunteer_constants.dart';

class VolunteerFormScreen extends StatefulWidget {
  const VolunteerFormScreen({super.key});

  @override
  State<VolunteerFormScreen> createState() => _VolunteerFormScreenState();
}

class _VolunteerFormScreenState extends State<VolunteerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _motivationController = TextEditingController();
  final _availabilityController = TextEditingController();

  final Set<String> _selectedSkills = {};
  String? _selectedGovernorate;
  String? _selectedGender;
  bool _agreedToPolicy = false;
  File? _portfolioFile;

  bool get _needsPortfolio => VolunteerSkills.needsPortfolio(_selectedSkills);

  @override
  void dispose() {
    _phoneController.dispose();
    _occupationController.dispose();
    _motivationController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skillKey) {
    setState(() {
      if (_selectedSkills.contains(skillKey)) {
        _selectedSkills.remove(skillKey);
      } else if (_selectedSkills.length < VolunteerSkills.maxSelection) {
        _selectedSkills.add(skillKey);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('volunteer_skills_max'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!VolunteerSkills.needsPortfolio(_selectedSkills)) {
        _portfolioFile = null;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      _showError('volunteer_skills_required');
      return;
    }
    if (_selectedGovernorate == null) {
      _showError('volunteer_governorate_required');
      return;
    }
    if (_needsPortfolio && _portfolioFile == null) {
      _showError('volunteer_portfolio_required');
      return;
    }
    if (!_agreedToPolicy) {
      _showError('volunteer_policy_required');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('volunteer_success_title'.tr()),
        content: Text('volunteer_success_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showError(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(key.tr()), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('volunteer_form_title'.tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              'volunteer_form_subtitle'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'volunteer_section_personal'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'volunteer_phone'.tr(),
              hint: 'volunteer_phone_hint'.tr(),
              prefixIcon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.trim().length < 9 ? 'volunteer_phone_error'.tr() : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'volunteer_gender'.tr(),
              hint: 'volunteer_gender_hint'.tr(),
              value: _selectedGender,
              items: const ['gender_male', 'gender_female'],
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'volunteer_occupation'.tr(),
              hint: 'volunteer_occupation_hint'.tr(),
              prefixIcon: Icons.work_outline,
              controller: _occupationController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'volunteer_occupation_error'.tr() : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'volunteer_governorate'.tr(),
              hint: 'volunteer_governorate_hint'.tr(),
              value: _selectedGovernorate,
              items: SyrianGovernorates.keys,
              onChanged: (v) => setState(() => _selectedGovernorate = v),
            ),
            const SizedBox(height: 28),
            Text(
              'volunteer_section_skills'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'volunteer_skills_hint'.tr(
                namedArgs: {'max': '${VolunteerSkills.maxSelection}'},
              ),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            _buildSkillsGrid(),
            if (_needsPortfolio) ...[
              const SizedBox(height: 20),
              DocumentUploadBox(
                label: 'volunteer_portfolio_label'.tr(),
                hint: 'volunteer_portfolio_hint'.tr(),
                supportedFormats: 'volunteer_portfolio_formats'.tr(),
                onFileSelected: (file) => setState(() => _portfolioFile = file),
              ),
              const SizedBox(height: 6),
              Text(
                'volunteer_portfolio_note'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'volunteer_section_availability'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'volunteer_availability'.tr(),
              hint: 'volunteer_availability_hint'.tr(),
              prefixIcon: Icons.schedule_outlined,
              controller: _availabilityController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'volunteer_availability_error'.tr() : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'volunteer_motivation'.tr(),
              hint: 'volunteer_motivation_hint'.tr(),
              prefixIcon: Icons.favorite_outline,
              controller: _motivationController,
              maxLines: 3,
              validator: (v) => v == null || v.trim().length < 10
                  ? 'volunteer_motivation_error'.tr()
                  : null,
            ),
            const SizedBox(height: 24),
            _buildPolicyCheckbox(cs),
            const SizedBox(height: 28),
            CustomButton(
              label: 'volunteer_submit'.tr(),
              icon: Icons.volunteer_activism,
              variant: ButtonVariant.primary,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items
              .map((key) => DropdownMenuItem(value: key, child: Text(key.tr())))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? '$label *' : null,
        ),
      ],
    );
  }

  Widget _buildSkillsGrid() {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VolunteerSkills.keys.map((skillKey) {
        final isSelected = _selectedSkills.contains(skillKey);
        return FilterChip(
          label: Text(skillKey.tr()),
          selected: isSelected,
          onSelected: (_) => _toggleSkill(skillKey),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : cs.onSurface,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : cs.outline.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  Widget _buildPolicyCheckbox(ColorScheme cs) {
    return InkWell(
      onTap: () => setState(() => _agreedToPolicy = !_agreedToPolicy),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _agreedToPolicy ? AppColors.primary : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToPolicy,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _agreedToPolicy = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'volunteer_policy_agree'.tr(),
                  style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
