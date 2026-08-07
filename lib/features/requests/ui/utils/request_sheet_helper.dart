import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/token_storage.dart';
import '../../../../core/router/app_routes.dart';
import '../screens/request_sheet.dart';

Future<void> showBeneficiaryRequestSheet(BuildContext context) async {
  final hasToken = await TokenStorage().hasToken();
  if (!context.mounted) return;

  if (!hasToken) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('auth_login_required_for_request'.tr())),
    );
    context.go(AppRoutes.loginBeneficiary);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const RequestSheet(),
  );
}
