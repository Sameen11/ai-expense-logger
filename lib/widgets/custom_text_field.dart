import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // The InputDecorations are now defined in AppTheme (lib/core/theme/app_theme.dart)
    // So we don't need to hardcode styles here.
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
        // Borders and Fill colors are handled globally in ThemeData
      ),
    );
  }
}
