import 'package:flutter/widgets.dart';

/// Radios oficiales de Coach App Mobile.
abstract final class AppRadius {
  AppRadius._();

  static const Radius xs = Radius.circular(4);
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(20);
  static const Radius xxl = Radius.circular(24);

  static const BorderRadius borderXs = BorderRadius.all(xs);
  static const BorderRadius borderSm = BorderRadius.all(sm);
  static const BorderRadius borderMd = BorderRadius.all(md);
  static const BorderRadius borderLg = BorderRadius.all(lg);
  static const BorderRadius borderXl = BorderRadius.all(xl);
  static const BorderRadius borderXxl = BorderRadius.all(xxl);
}