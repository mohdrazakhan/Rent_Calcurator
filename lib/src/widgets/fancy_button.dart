// lib/src/widgets/fancy_button.dart
import 'package:flutter/material.dart';

/// A stylish gradient-filled button with a subtle elevation and ripple.
/// Use like: FancyButton(label: 'Calculate', icon: Icons.calculate, onTap: () { ... })
class FancyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const FancyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).primaryColor;
    final colors = [base, base.withValues(alpha: 0.9)];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: begin, end: end),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
