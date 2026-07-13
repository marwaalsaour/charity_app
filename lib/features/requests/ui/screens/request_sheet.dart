import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/request_card.dart';

class RequestSheet extends StatelessWidget {
  const RequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    color: cs.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'request_sheet_heading'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
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
                  onRequest: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.medicalRequest);
                  },
                ),
                const SizedBox(height: 14),
                RequestCard(
                  icon: Icons.school_rounded,
                  title: 'education'.tr(),
                  subtitle: 'education_desc'.tr(),
                  onRequest: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.educationRequest);
                  },
                ),
                const SizedBox(height: 14),
                RequestCard(
                  icon: Icons.favorite_rounded,
                  title: 'orphans'.tr(),
                  subtitle: 'orphans_desc'.tr(),
                  onRequest: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.orphanRequest);
                  },
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
