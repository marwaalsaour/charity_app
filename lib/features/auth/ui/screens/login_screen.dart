import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/user_role_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../logic/login_cubit.dart';
import '../../logic/login_state.dart';
import '../widgets/auth_method_toggle.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_role_badge.dart';
import '../widgets/auth_screen_header.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  int _selectedMethod = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _registerRoute => widget.role == UserRole.donor
      ? AppRoutes.registerDonor
      : AppRoutes.registerBeneficiary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            AuthScreenHeader(
              onBack: () => context.go(AppRoutes.onboarding),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthRoleBadge(role: widget.role),
                        const SizedBox(height: 20),
                        Text(
                          'auth_welcome_back'.tr(),
                          style: AppTextStyles.headline(context),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'auth_login_subtitle'.tr(),
                          style: AppTextStyles.subtitle(context),
                        ),
                        const SizedBox(height: 30),
                        AuthMethodToggle(
                          selectedMethod: _selectedMethod,
                          onChanged: (v) => setState(() => _selectedMethod = v),
                        ),
                        const SizedBox(height: 30),
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
                              if (v == null || v.isEmpty) {
                                return 'auth_email_required'.tr();
                              }
                              if (!v.contains('@')) {
                                return 'auth_email_invalid'.tr();
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'auth_password_label'.tr(),
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'auth_password_required'.tr();
                            }
                            if (v.length < 8) return 'auth_password_min'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        BlocConsumer<LoginCubit, LoginState>(
                          listener: (context, state) async {
                            if (state is LoginSuccess) {
                              await context
                                  .read<UserRoleCubit>()
                                  .setRole(widget.role);
                              if (!context.mounted) return;
                              context.go(widget.role.homeRoute);
                            } else if (state is LoginError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message.tr())),
                              );
                            }
                          },
                          builder: (context, state) {
                            return CustomButton(
                              label: 'login'.tr(),
                              height: 55,
                              variant: ButtonVariant.primary,
                              isLoading: state is LoginLoading,
                              onTap: state is LoginLoading
                                  ? null
                                  : () =>
                                      context.read<LoginCubit>().loginGuest(),
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'auth_no_account'.tr(),
                                style: AppTextStyles.subtitle(context),
                              ),
                              GestureDetector(
                                onTap: () => context.push(_registerRoute),
                                child: Text(
                                  'auth_register_link'.tr(),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
