import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';

class BeneficiaryDrawer extends StatelessWidget {
  const BeneficiaryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              color: AppColors.primary,
              child: Text(
                'beneficiary_portal'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: cs.primary),
              title: Text(
                'how_to_get_help'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryHowToGetHelp);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.info_outline, color: cs.primary),
              title: Text(
                'about_association'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryAbout);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.verified_user_outlined, color: cs.primary),
              title: Text(
                'transparency_file'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryTransparency);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.contact_mail_outlined, color: cs.primary),
              title: Text(
                'contact_us'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryContactUs);
              },
            ),
          ],
        ),
      ),
    );
  }
}
