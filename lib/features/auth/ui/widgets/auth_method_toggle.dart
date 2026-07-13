import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';

class AuthMethodToggle extends StatelessWidget {
  final int selectedMethod;
  final ValueChanged<int> onChanged;

  const AuthMethodToggle({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkInputFill : AppColors.lightInputFill;

    return Row(
      children: [
        Expanded(
          child: _ToggleItem(
            label: 'auth_phone'.tr(),
            selected: selectedMethod == 0,
            inactiveColor: inactiveColor,
            textColor: cs.onSurface,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleItem(
            label: 'auth_email'.tr(),
            selected: selectedMethod == 1,
            inactiveColor: inactiveColor,
            textColor: cs.onSurface,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color inactiveColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.inactiveColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : inactiveColor,
          borderRadius: BorderRadius.circular(AppRadius.xl + 10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
