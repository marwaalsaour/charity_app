import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';

class DonationClosedBox extends StatelessWidget {
  const DonationClosedBox({super.key, this.height = 54, this.compact = false});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final locale = context.locale;

    return Container(
      width: compact ? null : double.infinity,
      height: height,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 10 : AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          context.tr('donation_closed'),
          key: ValueKey('donation_closed_${locale.languageCode}'),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: compact ? 11 : 15,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
