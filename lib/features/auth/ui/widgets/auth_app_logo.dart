import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AuthAppLogo extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final double letterSpacing;

  const AuthAppLogo({
    super.key,
    this.logoSize = 72,
    this.fontSize = 22,
    this.letterSpacing = 4,
  });

  static const String logoAsset = 'assets/image/logo-green.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          logoAsset,
          height: logoSize,
          width: logoSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          'ATAA',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: letterSpacing,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
