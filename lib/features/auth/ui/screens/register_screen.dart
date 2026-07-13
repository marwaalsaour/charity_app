import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../logic/register_cubit.dart';
import '../../logic/register_state.dart';
import '../widgets/auth_method_toggle.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_role_badge.dart';
import '../widgets/auth_screen_header.dart';
import '../widgets/auth_section_title.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  File? _documentImage;
  int _selectedDoc = -1;
  int _selectedMethod = 0;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = '${now.day}/${now.month}/${now.year}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _loginRoute => widget.role == UserRole.donor
      ? AppRoutes.loginDonor
      : AppRoutes.loginBeneficiary;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            AuthScreenHeader(
              onBack: () {
                if (_currentStep == 2) {
                  setState(() => _currentStep = 1);
                } else {
                  context.go(_loginRoute);
                }
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthRoleBadge(role: widget.role),
        const SizedBox(height: 20),
        Text(
          'auth_create_account'.tr(),
          style: AppTextStyles.headline(context),
        ),
        const SizedBox(height: 20),
        AuthMethodToggle(
          selectedMethod: _selectedMethod,
          onChanged: (v) => setState(() => _selectedMethod = v),
        ),
        const SizedBox(height: 30),
        AuthSectionTitle(titleKey: 'auth_personal_info'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                label: 'auth_first_name'.tr(),
                hint: 'auth_first_name_hint'.tr(),
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'auth_field_required'.tr() : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                label: 'auth_last_name'.tr(),
                hint: 'auth_last_name_hint'.tr(),
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'auth_field_required'.tr() : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_selectedMethod == 0)
          AuthPhoneField(controller: _phoneController)
        else
          CustomTextField(
            controller: _emailController,
            label: 'auth_email_label'.tr(),
            hint: 'auth_email_placeholder'.tr(),
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'auth_email_required'.tr();
              if (!v.contains('@')) return 'auth_email_invalid'.tr();
              return null;
            },
          ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'auth_date_of_birth'.tr(),
          controller: _dateController,
          readOnly: true,
          onTap: _pickDate,
          suffixWidget: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'auth_address'.tr(),
          hint: 'auth_address_hint'.tr(),
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 30),
        AuthSectionTitle(titleKey: 'auth_profile_photo'),
        const SizedBox(height: 15),
        ImageUploadBox(
          label: 'auth_profile_photo'.tr(),
          hint: 'auth_upload_profile'.tr(),
          onImageSelected: (file) => setState(() => _profileImage = file),
        ),
        const SizedBox(height: 30),
        AuthSectionTitle(titleKey: 'auth_identity_document'),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () => setState(() => _selectedDoc = 0),
          child: _buildDocItem('auth_national_id'.tr(), _selectedDoc == 0),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _selectedDoc = 1),
          child: _buildDocItem('auth_passport'.tr(), _selectedDoc == 1),
        ),
        if (_selectedDoc >= 0) ...[
          const SizedBox(height: 16),
          ImageUploadBox(
            label: _selectedDoc == 0
                ? 'auth_national_id'.tr()
                : 'auth_passport'.tr(),
            hint: 'tap_upload'.tr(),
            onImageSelected: (file) => setState(() => _documentImage = file),
          ),
        ],
        const SizedBox(height: 30),
        CustomButton(
          label: 'next'.tr(),
          height: 55,
          variant: ButtonVariant.primary,
          onTap: () {
            if (!_formKey.currentState!.validate()) return;
            if (_profileImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auth_upload_profile'.tr())),
              );
              return;
            }
            if (_selectedDoc == -1) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auth_select_document'.tr())),
              );
              return;
            }
            if (_documentImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auth_upload_document'.tr())),
              );
              return;
            }
            setState(() => _currentStep = 2);
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.go(_loginRoute),
            child: Text(
              'auth_have_account'.tr(),
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionTitle(titleKey: 'auth_security_info'),
        const SizedBox(height: 10),
        Text(
          'auth_security_desc'.tr(),
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          label: 'auth_password_label'.tr(),
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          validator: (v) {
            if (v == null || v.length < 8) return 'auth_password_min'.tr();
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'auth_confirm_password'.tr(),
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          validator: (v) {
            if (v != _passwordController.text) {
              return 'auth_password_mismatch'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        BlocConsumer<RegisterCubit, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auth_register_success'.tr())),
              );
              context.go(_loginRoute);
            } else if (state is RegisterError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message.tr())));
            }
          },
          builder: (context, state) {
            return CustomButton(
              label: 'auth_create_account_btn'.tr(),
              height: 55,
              variant: ButtonVariant.primary,
              isLoading: state is RegisterLoading,
              onTap: state is RegisterLoading
                  ? null
                  : () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<RegisterCubit>().register(
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        phone: _phoneController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                    },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocItem(String title, bool selected) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.lightBorder,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Icon(Icons.badge, color: selected ? AppColors.primary : cs.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.lightTextHint,
          ),
        ],
      ),
    );
  }
}
