import 'package:flutter/material.dart';

/// Iconografía oficial.
///
/// Centraliza los iconos utilizados
/// por toda la aplicación.
abstract final class AppIcons {
  AppIcons._();

  static const IconData home = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData chat = Icons.chat_bubble_outline_rounded;
  static const IconData person = Icons.person_outline_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData favorite = Icons.favorite_border_rounded;
  static const IconData star = Icons.star_outline_rounded;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData next = Icons.arrow_forward_ios_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_circle_outline_rounded;
}