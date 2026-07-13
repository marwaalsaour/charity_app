import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../widgets/auth_app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.authHeaderBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const _LanguageToggle(),
                        const Spacer(),
                        SizedBox(
                          width: 72,
                          child: currentIndex < 2
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _controller.jumpToPage(2),
                                    child: Text(
                                      'skip'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AuthAppLogo(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _controller,
                          onPageChanged: (index) {
                            setState(() => currentIndex = index);
                          },
                          children: [
                            _buildPage(
                              image: 'assets/image/photo1.jpg',
                              title: 'onboarding_title_1'.tr(),
                              desc: 'onboarding_desc_1'.tr(),
                            ),
                            _buildPage(
                              image: 'assets/image/photo2.jpg',
                              title: 'onboarding_title_2'.tr(),
                              desc: 'onboarding_desc_2'.tr(),
                            ),
                            _buildPage(
                              image: 'assets/image/photo3.jpg',
                              title: 'onboarding_title_3'.tr(),
                              desc: 'onboarding_desc_3'.tr(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentIndex == index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? AppColors.primaryDark
                                  : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      if (currentIndex == 0)
                        CustomButton(
                          label: 'get_started'.tr(),
                          height: 55,
                          variant: ButtonVariant.primary,
                          onTap: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      if (currentIndex == 1)
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                label: 'back'.tr(),
                                height: 55,
                                variant: ButtonVariant.outline,
                                onTap: () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: 'next'.tr(),
                                height: 55,
                                variant: ButtonVariant.primary,
                                onTap: () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (currentIndex == 2) ...[
                        Text(
                          'choose_account_type'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle(context),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'login_as_donor'.tr(),
                          height: 55,
                          icon: Icons.favorite_rounded,
                          variant: ButtonVariant.primary,
                          onTap: () => context.go(AppRoutes.loginDonor),
                        ),
                        const SizedBox(height: 8),
                        /* GestureDetector(
                          onTap: () => context.go(AppRoutes.registerDonor),
                          child: Text(
                            'auth_register_as_donor'.tr(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),*/
                        const SizedBox(height: 12),
                        CustomButton(
                          label: 'login_as_beneficiary'.tr(),
                          height: 55,
                          icon: Icons.handshake_outlined,
                          variant: ButtonVariant.accent,
                          onTap: () => context.go(AppRoutes.loginBeneficiary),
                        ),
                        const SizedBox(height: 8),
                        /*GestureDetector(
                          onTap: () => context.go(AppRoutes.registerBeneficiary),
                          child: Text(
                            'auth_register_as_beneficiary'.tr(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),*/
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String desc,
  }) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.authHeaderBackground,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: Image.asset(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: AppTextStyles.title(context)),
        const SizedBox(height: 6),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(context),
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  void _toggleLocale(BuildContext context) {
    final current = context.locale.languageCode;
    if (current == 'ar') {
      context.setLocale(const Locale('en'));
    } else {
      context.setLocale(const Locale('ar'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode.toUpperCase();

    return GestureDetector(
      onTap: () => _toggleLocale(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              localeCode,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
