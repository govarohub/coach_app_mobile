import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Estilos disponibles para AppButton.
enum AppButtonStyle { primary, secondary, tertiary }

/// Botón corporativo con soporte para múltiples estilos.
/// 
/// Proporciona 3 estilos:
/// - Primary: Naranja oscuro, sólido
/// - Secondary: Outline naranja, sin relleno
/// - Tertiary: Texto puro, sin borde
class AppButton extends StatelessWidget {
  /// Texto que se muestra en el botón.
  final String label;

  /// Callback ejecutado cuando se presiona el botón.
  final VoidCallback onPressed;

  /// Estilo visual del botón.
  final AppButtonStyle style;

  /// Si true, muestra un spinner y desactiva el botón.
  final bool isLoading;

  /// Ancho personalizado (por defecto, full width).
  final double? width;

  /// Alto personalizado (por defecto, 48px).
  final double height;

  /// Ícono opcional (izquierda del texto).
  final IconData? icon;

  /// Espaciado entre ícono y texto.
  final double iconSpacing;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.icon,
    this.iconSpacing = AppDimensions.md,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    if (isLoading) {
      return _buildLoadingButton();
    }

    return switch (style) {
      AppButtonStyle.primary => _buildPrimaryButton(),
      AppButtonStyle.secondary => _buildSecondaryButton(),
      AppButtonStyle.tertiary => _buildTertiaryButton(),
    };
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.textDisabled,
        disabledForegroundColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        disabledForegroundColor: AppColors.textDisabled,
        side: BorderSide(
          color: AppColors.primaryDark,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildTertiaryButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        disabledForegroundColor: AppColors.textDisabled,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      decoration: BoxDecoration(
        color: style == AppButtonStyle.primary
            ? AppColors.textDisabled
            : Colors.transparent,
        border: style != AppButtonStyle.primary
            ? Border.all(color: AppColors.textDisabled, width: 1.5)
            : null,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconSize),
          SizedBox(width: iconSpacing),
          Text(label),
        ],
      );
    }

    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
