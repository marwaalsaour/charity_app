import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLaunchHelper {
  ExternalLaunchHelper._();

  static Future<void> copyText(
    BuildContext context,
    String text, {
    String messageKey = 'phone_copied',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageKey.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<void> openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('open_link_failed'.tr())),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('open_link_failed'.tr())),
        );
      }
    }
  }

  static Future<void> openEmail(
    BuildContext context, {
    required String email,
  }) async {
    final subject = Uri.encodeComponent('contact_email_subject'.tr());
    final uri = Uri.parse('mailto:$email?subject=$subject');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('open_link_failed'.tr())),
      );
    }
  }

  static Future<void> openSocial(
    BuildContext context, {
    required String appUri,
    required String webUri,
  }) async {
    try {
      final app = Uri.parse(appUri);
      if (await canLaunchUrl(app)) {
        final ok = await launchUrl(app, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      final web = Uri.parse(webUri);
      final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('open_link_failed'.tr())),
        );
      }
    } catch (_) {
      try {
        await launchUrl(
          Uri.parse(webUri),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('open_link_failed'.tr())),
          );
        }
      }
    }
  }
}
