import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Breakpoint dan lebar konten bersama untuk semua layar.
abstract final class Breakpoints {
  static const double wide = 700;
  static const double maxContentWidth = 1100;
  static bool isWide(double contentWidth) => contentWidth >= wide;
}

/// Memusatkan konten dan membatasi lebarnya di layar besar.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: child,
        ),
      );
}

/// Body layar: SafeArea + scroll (aman untuk keyboard) + batas lebar + deteksi
/// layar lebar. [fillHeight] memusatkan konten secara vertikal bila pendek.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.builder,
    this.padding = const EdgeInsets.all(20),
    this.fillHeight = false,
  });

  final Widget Function(BuildContext context, bool wide) builder;
  final EdgeInsets padding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = Breakpoints.isWide(box.maxWidth - padding.horizontal);
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: fillHeight
                    ? math.max(0.0, box.maxHeight - padding.vertical)
                    : 0.0,
              ),
              child: ContentWidth(child: builder(context, wide)),
            ),
          );
        },
      ),
    );
  }
}
