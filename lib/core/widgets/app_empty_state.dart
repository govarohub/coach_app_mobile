import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';
import 'app_button.dart';

/// Estado vacío corporativo.
/// 
/// Muestra cuando no hay datos/resultados. Incluye:
/// - Ícono ilustrativo
/// - Título
/// - Descripción
/// - Botón CTA opcional
class AppEmptyState extends StatelessWidget {
  /// Ícono a mostrar.
  final IconData icon;

  /// Título del estado.
  final String title;

  /// Descripción (opcional).
  final String? description;

  /// Botón CTA (opcional).
  final String? actionLabel;

  /// Callback del botón CTA.
  final VoidCallback? onAction;

  /// Tamaño del ícono.
  final double iconSize;

  /// Color del ícono.
  final Color iconColor;

  /// Alineación vertical del contenido.
  /// Por defecto, centrado.
  final MainAxisAlignment mainAxisAlignment;

  const AppEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor = AppColors.primary,
    this.mainAxisAlignment = MainAxisAlignment.center,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono
            Icon(
              icon,
              size: iconSize,
              color: iconColor.withValues(alpha: 0.6),
            ),
            SizedBox(height: AppDimensions.xl),

            // Título
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Descripción
            if (description != null) ...[
              SizedBox(height: AppDimensions.md),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                child: Text(
                  description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Botón CTA
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppDimensions.xl),
              SizedBox(
                width: 200,
                child: AppButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  style: AppButtonStyle.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error corporativo.
/// Similar a AppEmptyState pero para errores.
class AppErrorState extends StatelessWidget {
  /// Título del error.
  final String title;

  /// Descripción del error.
  final String? description;

  /// Botón para reintentar.
  final String? retryLabel;

  /// Callback de reintentar.
  final VoidCallback? onRetry;

  /// Código de error a mostrar (opcional).
  final String? errorCode;

  const AppErrorState({
    required this.title,
    this.description,
    this.retryLabel = 'Reintentar',
    this.onRetry,
    this.errorCode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono de error
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
            SizedBox(height: AppDimensions.xl),

            // Título
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Descripción
            if (description != null) ...[
              SizedBox(height: AppDimensions.md),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                child: Text(
                  description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Código de error
            if (errorCode != null) ...[
              SizedBox(height: AppDimensions.md),
              Text(
                'Código: $errorCode',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDisabled,
                ),
              ),
            ],

            // Botón de reintentar
            if (onRetry != null) ...[
              SizedBox(height: AppDimensions.xl),
              SizedBox(
                width: 200,
                child: AppButton(
                  label: retryLabel ?? 'Reintentar',
                  onPressed: onRetry!,
                  style: AppButtonStyle.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
