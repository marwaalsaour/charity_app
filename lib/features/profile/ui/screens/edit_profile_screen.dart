import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/ui/widgets/auth_phone_field.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../widgets/profile_avatar_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _repository = UserProfileRepository();
  final _authRepository = AuthRepository();

  String? _imagePath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final saved = await _repository.getProfile();
    if (!mounted) return;

    if (saved != null) {
      _firstNameController.text = saved.firstName;
      _lastNameController.text = saved.lastName;
      _phoneController.text = saved.phone;
      _addressController.text = saved.address;
      _imagePath = saved.imagePath;
    } else {
      _firstNameController.text = 'profile_default_first_name'.tr();
      _lastNameController.text = 'profile_default_last_name'.tr();
    }

    setState(() => _loading = false);

    final remote = await _authRepository.syncProfile();
    if (!mounted || remote == null) return;
    setState(() {
      _firstNameController.text = remote.firstName;
      _lastNameController.text = remote.lastName;
      _phoneController.text = remote.phone;
      _addressController.text = remote.address;
      _imagePath = remote.imagePath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _authRepository.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        localImagePath: _imagePath,
      );
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile_saved'.tr())),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.tr())),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile_update_failed'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr()),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text(
                    'save_changes'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Center(
                    child: Column(
                      children: [
                        ProfileAvatarPicker(
                          imagePath: _imagePath,
                          onImageChanged: (path) =>
                              setState(() => _imagePath = path),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'auth_profile_photo'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: ext.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ext.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: ext.border),
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'auth_first_name'.tr(),
                          hint: 'auth_first_name_hint'.tr(),
                          prefixIcon: Icons.person_outline,
                          controller: _firstNameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'profile_first_name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'auth_last_name'.tr(),
                          hint: 'auth_last_name_hint'.tr(),
                          prefixIcon: Icons.badge_outlined,
                          controller: _lastNameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'profile_last_name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AuthPhoneField(controller: _phoneController),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'auth_address'.tr(),
                          hint: 'auth_address_hint'.tr(),
                          prefixIcon: Icons.location_on_outlined,
                          controller: _addressController,
                          maxLines: 3,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'profile_address_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'save_changes'.tr(),
                    variant: ButtonVariant.primary,
                    isLoading: _saving,
                    onTap: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
