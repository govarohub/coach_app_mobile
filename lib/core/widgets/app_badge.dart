import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Tipo de badge.
enum BadgeType { success, warning, error, info, neutral }

/// Badge corporativo para mostrar estados y tags.
/// 
/// Puede ser:
/// - Solo ícono
/// - Solo texto
/// - Ícono + texto
class AppBadge extends StatelessWidget {
  /// Tipo de badge (define color).
  final BadgeType type;

  /// Texto del badge.
  final String? label;

  /// Ícono del badge.
  final IconData? icon;

  /// Tamaño del ícono.
  final double iconSize;

  /// Callback al presionar.
  final VoidCallback? onTap;

  const AppBadge({
    this.type = BadgeType.neutral,
    this.label,
    this.icon,
    this.iconSize = AppDimensions.iconSize,
    this.onTap,
    Key? key,
  }) : super(key: key);

  Color get _backgroundColor => switch (type) {
    BadgeType.success => AppColors.success.withValues(alpha: 0.1),
    BadgeType.warning => AppColors.warning.withValues(alpha: 0.1),
    BadgeType.error => AppColors.error.withValues(alpha: 0.1),
    BadgeType.info => AppColors.info.withValues(alpha: 0.1),
    BadgeType.neutral => AppColors.textDisabled.withValues(alpha: 0.1),
  };

  Color get _textColor => switch (type) {
    BadgeType.success => AppColors.success,
    BadgeType.warning => AppColors.warning,
    BadgeType.error => AppColors.error,
    BadgeType.info => AppColors.info,
    BadgeType.neutral => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: _textColor,
            ),
            if (label != null) const SizedBox(width: AppDimensions.xs),
          ],
          if (label != null)
            Text(
              label!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Badge pequeño para mostrar en esquina de avatares.
class CircleBadge extends StatelessWidget {
  /// Tipo de badge.
  final BadgeType type;

  /// Tamaño del badge.
  final double size;

  const CircleBadge({
    this.type = BadgeType.success,
    this.size = 12,
    Key? key,
  }) : super(key: key);

  Color get _backgroundColor => switch (type) {
    BadgeType.success => AppColors.success,
    BadgeType.warning => AppColors.warning,
    BadgeType.error => AppColors.error,
    BadgeType.info => AppColors.info,
    BadgeType.neutral => AppColors.textDisabled,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _backgroundColor,
        border: Border.all(
          color: AppColors.surface,
          width: 1.5,
        ),
      ),
    );
  }
}
