import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/constants/association_contact.dart';
import '../../../../core/utils/external_launch_helper.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('contact_us'.tr()),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'contact_us_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _ContactTile(
            icon: Icons.phone_outlined,
            iconColor: AppColors.primary,
            title: 'contact_phone_label'.tr(),
            subtitle: AssociationContact.phoneDisplay,
            hint: 'contact_phone_hint'.tr(),
            onTap: () => ExternalLaunchHelper.copyText(
              context,
              AssociationContact.phoneDigits,
              messageKey: 'phone_copied',
            ),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email_outlined,
            iconColor: AppColors.accentDark,
            title: 'contact_email_label'.tr(),
            subtitle: AssociationContact.email,
            hint: 'contact_email_hint'.tr(),
            onTap: () => ExternalLaunchHelper.openEmail(
              context,
              email: AssociationContact.email,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'contact_social_title'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'contact_social_desc'.tr(),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SocialTile(
            icon: FontAwesomeIcons.instagram,
            color: const Color(0xFFE4405F),
            title: 'contact_instagram'.tr(),
            onTap: () => ExternalLaunchHelper.openSocial(
              context,
              appUri: AssociationContact.instagramApp,
              webUri: AssociationContact.instagramWeb,
            ),
          ),
          const SizedBox(height: 10),
          _SocialTile(
            icon: FontAwesomeIcons.facebookF,
            color: const Color(0xFF1877F2),
            title: 'contact_facebook'.tr(),
            onTap: () => ExternalLaunchHelper.openSocial(
              context,
              appUri: AssociationContact.facebookApp,
              webUri: AssociationContact.facebookWeb,
            ),
          ),
          const SizedBox(height: 10),
          _SocialTile(
            icon: FontAwesomeIcons.xTwitter,
            color: isDark ? Colors.white : Colors.black,
            title: 'contact_twitter'.tr(),
            onTap: () => ExternalLaunchHelper.openSocial(
              context,
              appUri: AssociationContact.twitterApp,
              webUri: AssociationContact.twitterWeb,
            ),
          ),
          const SizedBox(height: 10),
          _SocialTile(
            icon: FontAwesomeIcons.telegram,
            color: const Color(0xFF26A5E4),
            title: 'contact_telegram'.tr(),
            onTap: () => ExternalLaunchHelper.openSocial(
              context,
              appUri: AssociationContact.telegramApp,
              webUri: AssociationContact.telegramWeb,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Material(
      color: ext.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 12, color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final FaIconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Material(
      color: ext.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
