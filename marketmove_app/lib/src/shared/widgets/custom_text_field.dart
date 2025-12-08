import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketmove_app/src/shared/constants/app_colors.dart';

/// Widget de campo de texto personalizado con validaciones
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.inputFormatters,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            counterText: '', // Oculta el contador de caracteres
          ),
        ),
      ],
    );
  }
}

/// Campo de texto numérico
class NumericTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final bool allowDecimals;
  final void Function(String)? onChanged;

  const NumericTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.allowDecimals = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
      prefixIcon: prefixIcon,
      onChanged: onChanged,
      inputFormatters: [
        if (allowDecimals)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

/// Campo de texto de precio/moneda
class PriceTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PriceTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NumericTextField(
      label: label,
      hintText: '0.00',
      controller: controller,
      validator: validator,
      prefixIcon: Icons.attach_money,
      allowDecimals: true,
      onChanged: onChanged,
    );
  }
}

/// Validadores comunes
class Validators {
  /// Valida que el campo no esté vacío
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }

  /// Valida que sea un número válido
  static String? number(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'El valor'} debe ser un número válido';
    }
    return null;
  }

  /// Valida que sea un número mayor que cero
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return '${fieldName ?? 'El valor'} debe ser mayor que 0';
    }
    return null;
  }

  /// Valida que sea un número no negativo
  static String? nonNegativeNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return '${fieldName ?? 'El valor'} no puede ser negativo';
    }
    return null;
  }

  /// Valida email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Combina múltiples validadores
  static String? Function(String?) combine(
      List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
