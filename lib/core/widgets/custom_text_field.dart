import 'package:charity_app/core/constants/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.inputFormatters,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelColor = cs.onSurface;
    final iconColor = _focused
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.4);
    final fillColor = isDark
        ? AppColors.darkInputFill
        : AppColors.lightInputFill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText && _obscure,
            keyboardType: widget.keyboardType,
            textDirection: widget.obscureText ||
                    widget.keyboardType == TextInputType.emailAddress
                ? TextDirection.ltr
                : null,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            inputFormatters: widget.inputFormatters,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
                fontSize: 14,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.maxLines > 1 ? 14 : 0,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: iconColor, size: 20)
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : widget.suffixWidget,
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
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.large),
                borderSide: BorderSide(color: cs.error, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
