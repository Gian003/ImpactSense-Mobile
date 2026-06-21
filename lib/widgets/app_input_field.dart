import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Shared teal-bordered text field used across all screens.
/// Set [compact] to true for tighter layouts (personal info, add contact).
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.compact = false,
  });

  final String hint;
  final TextEditingController? controller;
  final FaIconData? prefixIcon;
  final bool obscureText;
  final FaIconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final bool compact;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 13 : 14;
    final EdgeInsets padding = compact
        ? const EdgeInsets.symmetric(vertical: 14, horizontal: 14)
        : const EdgeInsets.symmetric(vertical: 16, horizontal: 16);
    final double iconSize = compact ? 16 : 18;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: 'Montserrat', fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: fontSize,
          color: Colors.grey[500],
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(prefixIcon, color: _primaryColor, size: iconSize),
              )
            : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child:
                      FaIcon(suffixIcon, color: Colors.grey[500], size: iconSize),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: padding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
