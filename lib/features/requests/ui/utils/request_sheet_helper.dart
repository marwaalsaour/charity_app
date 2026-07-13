import 'package:flutter/material.dart';

import '../screens/request_sheet.dart';

void showBeneficiaryRequestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const RequestSheet(),
  );
}
