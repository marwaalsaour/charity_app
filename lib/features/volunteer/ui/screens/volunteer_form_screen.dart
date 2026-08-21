import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/data/auth_phone.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../notifications/data/notification_helper.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../data/repositories/volunteer_api_repository.dart';
import '../../data/volunteer_constants.dart';

class _GovOption {
  const _GovOption({required this.id, required this.name});
  final int id;
  final String name;
}

/// Association volunteer application — POST /volunteer/apply (GitHub API).
class VolunteerFormScreen extends StatefulWidget {
  const VolunteerFormScreen({super.key});

  @override
  State<VolunteerFormScreen> createState() => _VolunteerFormScreenState();
}

class _VolunteerFormScreenState extends State<VolunteerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _occupationController = TextEditingController();
  final _motivationController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _phoneController = TextEditingController();

  final Set<String> _selectedSkills = {};
  String? _selectedGender; // male | female
  /// Selected governorate id (API requires governorate_id; UI shows name).
  int? _selectedGovernorateId;
  List<_GovOption> _governorates = const [];
  bool _loadingGovs = true;
  bool _agreedToPolicy = false;
  bool _submitting = false;
  String? _existingStatus; // pending | approved | rejected

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
    _loadExistingApplication();
    _loadProfilePhone();
  }

  Future<void> _loadProfilePhone() async {
    final remote = await AuthRepository().syncProfile();
    final profile = remote ?? await UserProfileRepository().getProfile();
    if (!mounted) return;
    final phone = profile?.phone.trim() ?? '';
    if (phone.isEmpty) return;
    setState(() => _phoneController.text = phone);
  }

  Future<void> _loadExistingApplication() async {
    final app =
        await VolunteerApiRepository().fetchMyAssociationApplication();
    if (!mounted || app == null) return;
    final status = app['status']?.toString().toLowerCase();
    if (status == null || status.isEmpty) return;
    setState(() => _existingStatus = status);
  }

  Future<void> _loadGovernorates() async {
    try {
      final response = await ApiClient.instance.dio.get('/governorates');
      final list = _parseGovernorates(response.data);
      if (!mounted) return;
      setState(() {
        _governorates = list;
        _loadingGovs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGovs = false);
    }
  }

  List<_GovOption> _parseGovernorates(dynamic data) {
    List? raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final nested = data['data'] ?? data['governorates'];
      if (nested is List) raw = nested;
    }
    if (raw == null) return const [];

    final list = <_GovOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id'];
      final name = item['name']?.toString().trim() ?? '';
      final idInt = id is num ? id.toInt() : int.tryParse(id?.toString() ?? '');
      if (idInt != null && name.isNotEmpty) {
        list.add(_GovOption(id: idInt, name: name));
      }
    }
    return list;
  }

  @override
  void dispose() {
    _occupationController.dispose();
    _motivationController.dispose();
    _availabilityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleSkill(String apiKey) {
    setState(() {
      if (_selectedSkills.contains(apiKey)) {
        _selectedSkills.remove(apiKey);
      } else if (_selectedSkills.length < VolunteerSkills.maxSelection) {
        _selectedSkills.add(apiKey);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('volunteer_skills_max'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_existingStatus == 'pending' ||
        _existingStatus == 'approved' ||
        _existingStatus == 'suspended') {
      _showError(_existingStatus == 'approved' || _existingStatus == 'suspended'
          ? 'volunteer_already_approved'
          : 'volunteer_application_pending');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      _showError('volunteer_skills_required');
      return;
    }
    if (_selectedGovernorateId == null) {
      _showError('volunteer_governorate_required');
      return;
    }
    if (_selectedGender == null) {
      _showError('volunteer_gender_hint');
      return;
    }
    if (!_agreedToPolicy) {
      _showError('volunteer_policy_required');
      return;
    }

    var profile = await AuthRepository().syncProfile();
    profile ??= await UserProfileRepository().getProfile();
    final phone = AuthPhone.digitsOnly(
      profile?.phone ?? _phoneController.text,
    );
    if (phone.isEmpty) {
      _showError('volunteer_phone_from_profile_required');
      return;
    }

    setState(() => _submitting = true);
    try {
      await VolunteerApiRepository().applyToAssociation(
        phone: phone,
        gender: _selectedGender!,
        occupation: _occupationController.text.trim(),
        governorateId: _selectedGovernorateId!,
        skills: _selectedSkills.toList(),
        availability: _availabilityController.text.trim(),
        description: _motivationController.text.trim(),
      );

      await NotificationHelper.notifyVolunteerSubmitted();

      if (!mounted) return;
      setState(() => _existingStatus = 'pending');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('donate_error_generic');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      appBar: AtaaAppBar(title: 'volunteer_form_title'.tr()),
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
            if (_existingStatus != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _existingStatus == 'pending'
                      ? 'volunteer_application_pending'.tr()
                      : _existingStatus == 'approved'
                          ? 'volunteer_already_approved'.tr()
                          : 'volunteer_status_rejected'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'volunteer_section_personal'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'volunteer_phone'.tr(),
              hint: 'volunteer_phone_from_profile_hint'.tr(),
              prefixIcon: Icons.phone_outlined,
              controller: _phoneController,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildGenderDropdown(),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'volunteer_occupation'.tr(),
              hint: 'volunteer_occupation_hint'.tr(),
              prefixIcon: Icons.work_outline,
              controller: _occupationController,
            ),
            const SizedBox(height: 16),
            if (_loadingGovs)
              const Center(child: CircularProgressIndicator())
            else
              _buildGovernorateDropdown(),
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
              label: _submitting ? '...' : 'volunteer_submit'.tr(),
              icon: Icons.volunteer_activism,
              variant: ButtonVariant.primary,
              onTap: (_submitting ||
                      _existingStatus == 'pending' ||
                      _existingStatus == 'approved' ||
                      _existingStatus == 'suspended')
                  ? null
                  : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'volunteer_gender'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            hintText: 'volunteer_gender_hint'.tr(),
            filled: true,
            fillColor:
                isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: [
            DropdownMenuItem(value: 'male', child: Text('gender_male'.tr())),
            DropdownMenuItem(
                value: 'female', child: Text('gender_female'.tr())),
          ],
          onChanged: (v) => setState(() => _selectedGender = v),
          validator: (v) => v == null ? 'volunteer_gender_hint'.tr() : null,
        ),
      ],
    );
  }

  Widget _buildGovernorateDropdown() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'volunteer_governorate'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        // UI shows governorate name; API receives governorate_id.
        DropdownButtonFormField<int>(
          initialValue: _selectedGovernorateId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'volunteer_governorate_hint'.tr(),
            filled: true,
            fillColor:
                isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _governorates
              .map(
                (g) => DropdownMenuItem<int>(
                  value: g.id,
                  child: Text(g.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedGovernorateId = v),
          validator: (v) =>
              v == null ? 'volunteer_governorate_required'.tr() : null,
        ),
      ],
    );
  }

  Widget _buildSkillsGrid() {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VolunteerSkills.apiKeys.map((apiKey) {
        final isSelected = _selectedSkills.contains(apiKey);
        return FilterChip(
          label: Text(VolunteerSkills.labelKey(apiKey).tr()),
          selected: isSelected,
          onSelected: (_) => _toggleSkill(apiKey),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : cs.onSurface,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : cs.outline.withValues(alpha: 0.3),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            color: _agreedToPolicy
                ? AppColors.primary
                : cs.outline.withValues(alpha: 0.3),
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
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
