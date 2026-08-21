import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Consent checkbox: allow publishing the beneficiary name on donor cards.
class ShowNameConsentTile extends StatelessWidget {
  const ShowNameConsentTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(
        'show_beneficiary_name_consent'.tr(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          height: 1.35,
        ),
      ),
    );
  }
}
