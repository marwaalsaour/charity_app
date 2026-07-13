import 'dart:io';
import 'package:charity_app/core/constants/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class ImageUploadBox extends StatefulWidget {
  final String label;
  final String hint;
  final String supportedFormats;
  final ValueChanged<File?>? onImageSelected;

  const ImageUploadBox({
    super.key,
    required this.label,
    this.hint = 'Tap to upload photo',
    this.supportedFormats = 'JPG, PNG supported',
    this.onImageSelected,
  });

  @override
  State<ImageUploadBox> createState() => _ImageUploadBoxState();
}

class _ImageUploadBoxState extends State<ImageUploadBox> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pick() async {
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
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primary.withOpacity(0.1),
                  child: Icon(Icons.camera_alt, color: cs.primary),
                ),
                title: Text('Camera', style: TextStyle(color: cs.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primary.withOpacity(0.1),
                  child: Icon(Icons.photo_library, color: cs.primary),
                ),
                title: Text('Gallery', style: TextStyle(color: cs.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_image != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.error.withOpacity(0.1),
                    child: Icon(Icons.delete_outline, color: cs.error),
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: cs.error),
                  ),
                  onTap: () {
                    setState(() => _image = null);
                    widget.onImageSelected?.call(null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _image = file);
      widget.onImageSelected?.call(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? AppColors.darkInputFill
        : AppColors.lightInputFill;
    final borderColor = _image != null
        ? cs.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: _image != null ? 160 : 110,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: _image != null ? _preview(cs) : _placeholder(cs),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_upload_outlined, color: cs.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          widget.hint,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.supportedFormats,
          style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
        ),
      ],
    );
  }

  Widget _preview(ColorScheme cs) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium - 1),
          child: Image.file(
            _image!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
