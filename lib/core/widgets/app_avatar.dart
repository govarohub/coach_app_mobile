import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Tamaño del avatar.
enum AvatarSize { small, medium, large }

/// Avatar corporativo para perfiles y usuarios.
/// 
/// Soporta imagen desde URL, imagen local, o fallback con iniciales.
/// Puede mostrar badge de verificación o estado online.
class AppAvatar extends StatelessWidget {
  /// URL de la imagen (prioridad 1).
  final String? imageUrl;

  /// Widget de imagen (prioridad 2).
  final ImageProvider? image;

  /// Iniciales como fallback (prioridad 3).
  final String? initials;

  /// Tamaño del avatar.
  final AvatarSize size;

  /// Badge para mostrar (verificado, online, etc).
  final Widget? badge;

  /// Color de fondo para iniciales.
  final Color backgroundColor;

  /// Color del texto para iniciales.
  final Color textColor;

  /// Borde personalizado.
  final Border? border;

  const AppAvatar({
    this.imageUrl,
    this.image,
    this.initials,
    this.size = AvatarSize.medium,
    this.badge,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.border,
    Key? key,
  }) : super(key: key);

  double get _diameter => switch (size) {
    AvatarSize.small => AppDimensions.avatarSmall,
    AvatarSize.medium => AppDimensions.avatarMedium,
    AvatarSize.large => AppDimensions.avatarLarge,
  };

  double get _fontSize => switch (size) {
    AvatarSize.small => 14,
    AvatarSize.medium => 18,
    AvatarSize.large => 28,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: border,
          ),
          child: _buildContent(),
        ),
        if (badge != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: badge!,
          ),
      ],
    );
  }

  Widget _buildContent() {
    // Imagen desde URL
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: _diameter * 0.5,
                height: _diameter * 0.5,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    // Imagen local
    if (image != null) {
      return ClipOval(
        child: Image(
          image: image!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fallback: iniciales
    return _buildInitials();
  }

  Widget _buildInitials() {
    final text = initials ?? '?';
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Badge para mostrar en la esquina del avatar.
/// Por ejemplo: verificado, online, offline.
class AvatarBadge extends StatelessWidget {
  /// Tipo de badge.
  final AvatarBadgeType type;

  /// Tamaño del badge.
  final double size;

  const AvatarBadge({
    this.type = AvatarBadgeType.verified,
    this.size = 16,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, icon) = switch (type) {
      AvatarBadgeType.verified => (AppColors.primary, Icons.check_circle),
      AvatarBadgeType.online => (AppColors.success, Icons.circle),
      AvatarBadgeType.offline => (AppColors.textSecondary, Icons.circle),
      AvatarBadgeType.notification => (AppColors.warning, Icons.circle_notifications),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: AppColors.surface,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}

enum AvatarBadgeType { verified, online, offline, notification }
