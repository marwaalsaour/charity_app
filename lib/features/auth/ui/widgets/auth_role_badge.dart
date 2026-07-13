import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/constants/app_colors.dart';

class AuthRoleBadge extends StatelessWidget {
  final UserRole role;

  const AuthRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isDonor = role == UserRole.donor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isDonor ? AppColors.primary : AppColors.accent)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isDonor ? 'login_as_donor'.tr() : 'login_as_beneficiary'.tr(),
        style: TextStyle(
          color: isDonor ? AppColors.primaryDark : AppColors.accentDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
