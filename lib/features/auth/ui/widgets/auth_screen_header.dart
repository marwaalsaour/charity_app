import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'auth_app_logo.dart';

class AuthScreenHeader extends StatelessWidget {
  final VoidCallback onBack;

  const AuthScreenHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primaryDark,
              onPressed: onBack,
            ),
          ),
          const AuthAppLogo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
