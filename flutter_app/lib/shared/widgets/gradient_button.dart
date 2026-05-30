import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<Color>? colors;
  final Widget? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading   = false,
    this.width,
    this.padding,
    this.borderRadius = 12,
    this.colors,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale:    _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [AppTheme.goldLight, const Color(0xFFFFCC80)]
                    : (widget.colors ?? [AppTheme.goldPrimary, AppTheme.goldLight]),
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _hovered
                  ? [BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
                  : [],
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                      Text(widget.label, style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14,
                      )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
