import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 36,
    height: 1.08,
    fontWeight: FontWeight.w700,
  );
  static const headline = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
  );
  static const sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );
}
