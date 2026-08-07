import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/request_card.dart';

class RequestSheet extends StatelessWidget {
  const RequestSheet({super.key});

  void _openRequest(BuildContext context, String route) {
    // Capture router before closing the sheet — sheet context is invalid after pop.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: ext.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Text(
                  'submit_request'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'choose_assistance'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: ext.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Image.asset(
                  'assets/image/logo-green.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                Text(
                  'how_help_today'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'request_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: ext.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                RequestCard(
                  icon: Icons.medical_services_rounded,
                  title: 'medical'.tr(),
                  subtitle: 'medical_desc'.tr(),
                  onRequest: () =>
                      _openRequest(context, AppRoutes.medicalRequest),
                ),
                const SizedBox(height: 14),
                RequestCard(
                  icon: Icons.school_rounded,
                  title: 'education'.tr(),
                  subtitle: 'education_desc'.tr(),
                  onRequest: () =>
                      _openRequest(context, AppRoutes.educationRequest),
                ),
                const SizedBox(height: 14),
                RequestCard(
                  icon: Icons.favorite_rounded,
                  title: 'orphans'.tr(),
                  subtitle: 'orphans_desc'.tr(),
                  onRequest: () =>
                      _openRequest(context, AppRoutes.orphanRequest),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
