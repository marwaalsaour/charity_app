import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';

class BeneficiaryHomeScreen extends StatelessWidget {
  const BeneficiaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      drawer: const _BeneficiaryDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'beneficiary_welcome_title'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'beneficiary_welcome_desc'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: ext.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'submit_request'.tr(),
                    icon: Icons.add_circle_outline,
                    variant: ButtonVariant.primary,
                    onTap: () => showBeneficiaryRequestSheet(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'my_recent_requests'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RequestPreviewCard(
                    title: 'beneficiary_request_sample_1'.tr(),
                    status: 'beneficiary_status_pending'.tr(),
                    date: '2026-03-01',
                  ),
                  const SizedBox(height: 12),
                  _RequestPreviewCard(
                    title: 'beneficiary_request_sample_2'.tr(),
                    status: 'beneficiary_status_approved'.tr(),
                    date: '2026-02-15',
                    isApproved: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 52),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome_back'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'beneficiary_portal'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _RequestPreviewCard extends StatelessWidget {
  const _RequestPreviewCard({
    required this.title,
    required this.status,
    required this.date,
    this.isApproved = false,
  });

  final String title;
  final String status;
  final String date;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isApproved ? AppColors.success : AppColors.accent)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isApproved ? Icons.check_circle_outline : Icons.pending_outlined,
              color: isApproved ? AppColors.success : AppColors.accentDark,
            ),
          ),
          const SizedBox(width: 12),
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
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isApproved ? AppColors.success : ext.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(fontSize: 11, color: ext.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BeneficiaryDrawer extends StatelessWidget {
  const _BeneficiaryDrawer();

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
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 20,
              ),
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
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.contact_mail_outlined, color: cs.primary),
              title: Text(
                'contact_us'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
