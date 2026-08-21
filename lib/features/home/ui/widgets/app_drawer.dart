import 'package:charity_app/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme/theme_cubit.dart';
import '../../../../core/constants/app_theme/theme_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                'app_name'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.verified_user_outlined,
              title: 'transparency_file'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.donorTransparency);
              },
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.info_outline,
              title: 'about_association'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.donorAbout);
              },
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.contact_mail_outlined,
              title: 'contact_us'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.donorContactUs);
              },
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                final isDarkMode = state.mode == ThemeMode.dark;

                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(
                    isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: cs.primary,
                  ),
                  title: Text(
                    'dark_mode'.tr(),
                    style: TextStyle(color: cs.onSurface),
                  ),
                  value: isDarkMode,
                  activeThumbColor: AppColors.accent,
                  onChanged: (_) => context.read<ThemeCubit>().toggle(),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.language, color: cs.primary),
              title: Text(
                'language'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.locale.languageCode.toUpperCase(),
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              onTap: () {
                final current = context.locale.languageCode;
                if (current == 'ar') {
                  context.setLocale(const Locale('en'));
                } else {
                  context.setLocale(const Locale('ar'));
                }
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                label: 'volunteer_with_us'.tr(),
                icon: Icons.volunteer_activism,
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.volunteerForm);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: cs.primary),
      title: Text(
        title,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
