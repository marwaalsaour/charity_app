import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';

class AboutAssociationScreen extends StatelessWidget {
  const AboutAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = GoRouterState.of(context).uri.path;

    return Scaffold(
      key: ValueKey('about-${locale.languageCode}'),
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AtaaAppBar(
        title: 'about_association'.tr(),
        onBack: () => context.go(AppRoutes.homeForPath(path)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          _HeroCard(),
          const SizedBox(height: 20),
          _SectionCard(
            titleKey: 'about_who_title',
            bodyKey: 'about_who_body',
          ),
          const SizedBox(height: 12),
          _HighlightCard(
            icon: Icons.visibility_outlined,
            color: AppColors.primary,
            titleKey: 'about_vision_title',
            bodyKey: 'about_vision_body',
          ),
          const SizedBox(height: 12),
          _HighlightCard(
            icon: Icons.flag_outlined,
            color: AppColors.accentDark,
            titleKey: 'about_mission_title',
            bodyKey: 'about_mission_body',
          ),
          const SizedBox(height: 28),
          Text(
            'about_tasks_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'about_tasks_intro'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const _TaskCard(
            number: '01',
            icon: Icons.fact_check_outlined,
            titleKey: 'about_task1_title',
            bodyKey: 'about_task1_body',
          ),
          const _TaskCard(
            number: '02',
            icon: Icons.campaign_outlined,
            titleKey: 'about_task2_title',
            bodyKey: 'about_task2_body',
          ),
          const _TaskCard(
            number: '03',
            icon: Icons.medical_services_outlined,
            titleKey: 'about_task3_title',
            bodyKey: 'about_task3_body',
          ),
          const _TaskCard(
            number: '04',
            icon: Icons.school_outlined,
            titleKey: 'about_task4_title',
            bodyKey: 'about_task4_body',
          ),
          const _TaskCard(
            number: '05',
            icon: Icons.favorite_border_rounded,
            titleKey: 'about_task5_title',
            bodyKey: 'about_task5_body',
          ),
          const _TaskCard(
            number: '06',
            icon: Icons.groups_outlined,
            titleKey: 'about_task6_title',
            bodyKey: 'about_task6_body',
          ),
          const _TaskCard(
            number: '07',
            icon: Icons.volunteer_activism_outlined,
            titleKey: 'about_task7_title',
            bodyKey: 'about_task7_body',
          ),
          const _TaskCard(
            number: '08',
            icon: Icons.account_balance_wallet_outlined,
            titleKey: 'about_task8_title',
            bodyKey: 'about_task8_body',
          ),
          const SizedBox(height: 18),
          Text(
            'about_values_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          const _ValueCard(
            icon: Icons.verified_outlined,
            titleKey: 'about_value_transparency',
            bodyKey: 'about_value_transparency_body',
          ),
          const _ValueCard(
            icon: Icons.handshake_outlined,
            titleKey: 'about_value_dignity',
            bodyKey: 'about_value_dignity_body',
          ),
          const _ValueCard(
            icon: Icons.shield_outlined,
            titleKey: 'about_value_trust',
            bodyKey: 'about_value_trust_body',
          ),
          const _ValueCard(
            icon: Icons.auto_graph_outlined,
            titleKey: 'about_value_impact',
            bodyKey: 'about_value_impact_body',
          ),
          const SizedBox(height: 12),
          _CtaCard(
            onContact: () => context.push(AppRoutes.contactForPath(path)),
            onVolunteer: () => context.push(AppRoutes.volunteerForPath(path)),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Image.asset(
              'assets/image/logo-green.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.volunteer_activism,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'about_org_name'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'about_tagline'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.titleKey, required this.bodyKey});

  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleKey.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bodyKey.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: ext.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final Color color;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            titleKey.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bodyKey.tr(),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: ext.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.number,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final String number;
  final IconData icon;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: ext.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: ext.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKey.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bodyKey.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: ext.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: ext.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accentDark, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKey.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bodyKey.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: ext.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard({required this.onContact, required this.onVolunteer});

  final VoidCallback onContact;
  final VoidCallback onVolunteer;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'about_cta_title'.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'about_cta_body'.tr(),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'volunteer_with_us'.tr(),
            icon: Icons.volunteer_activism,
            onTap: onVolunteer,
          ),
          const SizedBox(height: 10),
          CustomButton(
            label: 'contact_us'.tr(),
            icon: Icons.contact_mail_outlined,
            variant: ButtonVariant.outline,
            onTap: onContact,
          ),
        ],
      ),
    );
  }
}
