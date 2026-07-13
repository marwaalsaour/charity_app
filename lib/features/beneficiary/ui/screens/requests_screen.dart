import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('my_requests'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'requests_screen_desc'.tr(),
            style: TextStyle(
              color: ext.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _RequestItem(
            title: 'beneficiary_request_sample_1'.tr(),
            status: 'beneficiary_status_pending'.tr(),
            date: '2026-03-01',
          ),
          _RequestItem(
            title: 'beneficiary_request_sample_2'.tr(),
            status: 'beneficiary_status_approved'.tr(),
            date: '2026-02-15',
            isApproved: true,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'new_request'.tr(),
            icon: Icons.add,
            variant: ButtonVariant.accent,
            onTap: () => showBeneficiaryRequestSheet(context),
          ),
        ],
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  const _RequestItem({
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
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: isApproved ? AppColors.success : AppColors.accentDark,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: isApproved
                      ? AppColors.success
                      : ext.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: ext.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
