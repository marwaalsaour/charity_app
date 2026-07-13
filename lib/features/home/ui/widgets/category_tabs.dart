import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme_extensions.dart';

class CategoryTabs extends StatelessWidget {
  final List<String> categoryKeys;
  final String selectedKey;
  final ValueChanged<String> onSelect;

  const CategoryTabs({
    super.key,
    required this.categoryKeys,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryKeys.length,
        itemBuilder: (context, i) {
          final key = categoryKeys[i];
          final isSelected = key == selectedKey;

          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : ext.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? cs.primary : ext.border,
                  width: 1,
                ),
              ),
              child: Text(
                key.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : ext.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
