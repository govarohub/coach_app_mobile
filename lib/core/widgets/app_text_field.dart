import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Campo de entrada corporativo.
/// 
/// Proporciona input visualmente consistente con soporte para:
/// - Etiqueta y hint
/// - Validación y mensajes de error
/// - Ícono prefijo/sufijo
/// - Caracteres contadores
class AppTextField extends StatefulWidget {
  /// Controlador del campo.
  final TextEditingController? controller;

  /// Etiqueta del campo.
  final String? label;

  /// Texto de sugerencia.
  final String? hint;

  /// Tipo de input.
  final TextInputType keyboardType;

  /// Callback cuando cambia el texto.
  final ValueChanged<String>? onChanged;

  /// Callback al completar edición.
  final VoidCallback? onEditingComplete;

  /// Validador.
  final String? Function(String?)? validator;

  /// Mensaje de error personalizado.
  final String? errorText;

  /// Ícono al inicio del campo.
  final IconData? prefixIcon;

  /// Ícono al final del campo.
  final IconData? suffixIcon;

  /// Callback para el ícono sufijo.
  final VoidCallback? onSuffixIconPressed;

  /// Si true, oculta el texto (para campos de contraseña).
  final bool obscureText;

  /// Permite multilínea.
  final int maxLines;

  /// Número máximo de caracteres.
  final int? maxLength;

  /// Si true, es de solo lectura.
  final bool readOnly;

  /// Si true, desactiva el campo.
  final bool enabled;

  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    super.key,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscure = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          obscureText: _obscure,
          maxLines: _obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconSize,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? GestureDetector(
                    onTap: widget.onSuffixIconPressed,
                    child: Icon(
                      widget.suffixIcon,
                      color: AppColors.textSecondary,
                      size: AppDimensions.iconSize,
                    ),
                  )
                : null,
            // Toggle obscure
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppDimensions.buttonHeight,
              minHeight: AppDimensions.buttonHeight,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            filled: true,
            fillColor: widget.enabled ? AppColors.surface : AppColors.background,
            counterText: '',
            errorText: widget.errorText,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.error,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (widget.maxLength != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
