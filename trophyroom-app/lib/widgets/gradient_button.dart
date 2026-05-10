import 'package:flutter/material.dart';

/// 渐变色按钮（替代 ElevatedButton）
/// - 主按钮：紫渐变 [Color(0xFF7C4DFF), Color(0xFF536DFE)]
/// - 次按钮：半透明描边
/// - 按压缩放动画
class GradientButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradientColors,
    this.height = 48,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 2,
  });

  /// Primary purple gradient
  factory GradientButton.primary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double height = 48,
  }) {
    return GradientButton(
      gradientColors: const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
      height: height,
      onPressed: onPressed,
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            )
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled ? null : (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: isDisabled
                ? LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[850]!],
                  )
                : widget.gradientColors != null
                    ? LinearGradient(
                        colors: widget.gradientColors!,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[700]!],
                      ),
            border: widget.borderWidth > 0
                ? Border.all(color: widget.borderColor ?? Colors.white.withOpacity(0.3), width: widget.borderWidth)
                : null,
            boxShadow: widget.elevation > 0 && !isDisabled
                ? [
                    BoxShadow(
                      color: (widget.gradientColors?.first ?? Colors.purple).withOpacity(0.3),
                      blurRadius: widget.elevation * 4,
                      offset: Offset(0, widget.elevation),
                    ),
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// 描边式次按钮（半透明背景）
class OutlinedGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const OutlinedGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      gradientColors: [Colors.transparent, Colors.transparent],
      borderColor: Colors.white.withOpacity(0.25),
      borderWidth: 1,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }
}
