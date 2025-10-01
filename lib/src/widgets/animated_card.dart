// lib/src/widgets/animated_card.dart
import 'package:flutter/material.dart';

/// A simple reusable card that animates into view with a slide+fade.
/// Use this to wrap any content that should appear with a subtle entrance.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final AxisDirection from; // direction where it slides from
  final Curve curve;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double elevation;

  const AnimatedCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.from = AxisDirection.down,
    this.curve = Curves.easeOut,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.elevation = 6.0,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    final beginOffset = () {
      switch (widget.from) {
        case AxisDirection.up:
          return const Offset(0, 0.08);
        case AxisDirection.down:
          return const Offset(0, -0.08);
        case AxisDirection.left:
          return const Offset(0.08, 0);
        case AxisDirection.right:
          return const Offset(-0.08, 0);
      }
    }();

    _offset = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    // start animation slightly after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Card(
          elevation: widget.elevation,
          shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
