import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';

class AuthPhoneField extends StatelessWidget {
  final TextEditingController controller;

  const AuthPhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? AppColors.darkInputFill : AppColors.lightInputFill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth_phone'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              alignment: Alignment.center,
              child: Text(
                '+963',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'auth_phone_required'.tr();
                  if (v.length != 9) return 'auth_phone_invalid'.tr();
                  return null;
                },
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'auth_phone_placeholder'.tr(),
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    borderSide: BorderSide(color: cs.error, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
