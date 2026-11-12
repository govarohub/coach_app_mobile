import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_dimensions.dart';
import '../../shared/design_system/colors/app_colors.dart';

/// Item de navegación inferior.
class BottomNavItem {
  /// Etiqueta del item.
  final String label;

  /// Ícono del item.
  final IconData icon;

  /// Ícono cuando está seleccionado (opcional).
  final IconData? selectedIcon;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

/// Navegación inferior corporativa.
/// 
/// Muestra items con ícono y etiqueta.
/// Solo el item seleccionado se muestra en naranja.
class AppBottomNavigation extends StatelessWidget {
  /// Items de navegación.
  final List<BottomNavItem> items;

  /// Índice del item seleccionado.
  final int currentIndex;

  /// Callback cuando se selecciona un item.
  final ValueChanged<int> onTap;

  /// Color de fondo.
  final Color backgroundColor;

  /// Elevación de la barra.
  final double elevation;

  /// Mostrar etiquetas siempre (default: true).
  final bool showLabels;

  const AppBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = AppColors.surface,
    this.elevation = 4,
    this.showLabels = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = items[index];
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Icon(
              isSelected && item.selectedIcon != null
                  ? item.selectedIcon!
                  : item.icon,
              color: isSelected
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
              size: AppDimensions.iconSize,
            ),

            // Etiqueta
            if (showLabels) ...[
              const SizedBox(height: AppDimensions.xs),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Indicador de selección (línea superior)
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.xs),
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
