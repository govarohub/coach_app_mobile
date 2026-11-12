import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Tarjeta corporativa reutilizable.
/// 
/// Proporciona una superficie elevada con bordes, sombras y estilo consistente.
/// Puede ser usada como contenedor para cualquier contenido.
class AppCard extends StatelessWidget {
  /// Contenido de la tarjeta.
  final Widget child;

  /// Espaciado interno (padding).
  final EdgeInsetsGeometry padding;

  /// Espaciado externo (margin).
  final EdgeInsetsGeometry? margin;

  /// Callback ejecutado cuando se presiona la tarjeta.
  /// Si es null, la tarjeta no responde a presiones.
  final VoidCallback? onTap;

  /// Radio de esquinas personalizado.
  final double borderRadius;

  /// Borde personalizado.
  final Border? border;

  /// Color de fondo personalizado.
  final Color backgroundColor;

  /// Sombra personalizada.
  /// Por defecto, usa AppShadows.small.
  final List<BoxShadow> shadows;

  /// Si true, cambia la elevación cuando se presiona.
  final bool hasHoverEffect;

  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.lg),
    this.margin,
    this.onTap,
    this.borderRadius = AppDimensions.radiusCard,
    this.border,
    this.backgroundColor = AppColors.surface,
    this.shadows = AppShadows.small,
    this.hasHoverEffect = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: AppColors.border,
              width: 1,
            ),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null && hasHoverEffect) {
      return _InkWellCard(
        onTap: onTap!,
        card: card,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Envoltorio interno para efecto de ripple con hover.
class _InkWellCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget card;

  const _InkWellCard({
    required this.onTap,
    required this.card,
  });

  @override
  State<_InkWellCard> createState() => _InkWellCardState();
}

class _InkWellCardState extends State<_InkWellCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
              _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: AnimatedOpacity(
            opacity: _isHovered ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: widget.card,
          ),
        ),
      ),
    );
  }
}
