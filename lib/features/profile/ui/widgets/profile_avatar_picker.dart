import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';

class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.imagePath,
    required this.onImageChanged,
    this.size = 112,
  });

  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final double size;

  Future<void> _pickImage(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'choose_source'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.camera_alt, color: cs.primary),
                ),
                title: Text('camera'.tr(), style: TextStyle(color: cs.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.photo_library, color: cs.primary),
                ),
                title: Text('gallery'.tr(), style: TextStyle(color: cs.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (imagePath != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.error.withValues(alpha: 0.1),
                    child: Icon(Icons.delete_outline, color: cs.error),
                  ),
                  title: Text(
                    'remove_photo'.tr(),
                    style: TextStyle(color: cs.error),
                  ),
                  onTap: () {
                    onImageChanged(null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      onImageChanged(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final borderColor = ext?.border ?? cs.outline;

    Widget avatarChild;
    final path = imagePath;
    if (path != null &&
        (path.startsWith('http://') || path.startsWith('https://'))) {
      avatarChild = ClipOval(
        child: Image.network(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(Icons.person, size: size * 0.45, color: cs.primary),
        ),
      );
    } else if (path != null && File(path).existsSync()) {
      avatarChild = ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      avatarChild = Icon(Icons.person, size: size * 0.45, color: cs.primary);
    }

    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: ext?.cardBackground ?? cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.25
                        : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: avatarChild,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
