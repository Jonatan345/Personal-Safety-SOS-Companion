import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu bersama. Dengan [onTap], kartu menampilkan efek tekan (ripple) dan
/// dibacakan satu kali sebagai tombol lewat [semanticLabel].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );

    if (onTap != null && semanticLabel != null) {
      card = Semantics(
        button: true,
        label: semanticLabel,
        hint: semanticHint,
        onTap: onTap,
        excludeSemantics: true,
        child: card,
      );
    }
    return card;
  }
}
