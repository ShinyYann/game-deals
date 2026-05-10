import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  // 快捷 Widget
  static const SizedBox hXs = SizedBox(height: xs);
  static const SizedBox hSm = SizedBox(height: sm);
  static const SizedBox hMd = SizedBox(height: md);
  static const SizedBox hLg = SizedBox(height: lg);
  static const SizedBox hXl = SizedBox(height: xl);
  static const SizedBox hXxl = SizedBox(height: xxl);

  static const SizedBox wXs = SizedBox(width: xs);
  static const SizedBox wSm = SizedBox(width: sm);
  static const SizedBox wMd = SizedBox(width: md);
  static const SizedBox wLg = SizedBox(width: lg);
  static const SizedBox wXl = SizedBox(width: xl);
  static const SizedBox wXxl = SizedBox(width: xxl);

  // 标准内边距
  static const EdgeInsets padSm = EdgeInsets.all(sm);
  static const EdgeInsets padMd = EdgeInsets.all(md);
  static const EdgeInsets padLg = EdgeInsets.all(lg);
  static const EdgeInsets padXl = EdgeInsets.all(xl);

  // 水平/垂直
  static const EdgeInsets hPadLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets vPadLg = EdgeInsets.symmetric(vertical: lg);
}
