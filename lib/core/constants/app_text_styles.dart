import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: AppColors.lightTextSecond,
    );
  }

  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }
}
