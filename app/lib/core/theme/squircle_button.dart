import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// The single sanctioned button primitive. Squircle (radius md), height 52.
/// Primary fills with the blue gradient + glow and white text; press scales
/// to 0.97.
class RoostButton extends StatefulWidget {
  const RoostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = RoostButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final RoostButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<RoostButton> createState() => _RoostButtonState();
}

enum RoostButtonVariant { primary, secondary, ghost, destructive }

class _RoostButtonState extends State<RoostButton> {
  bool _pressed = false;

  bool get _isPrimary => widget.variant == RoostButtonVariant.primary;

  Color get _bg => switch (widget.variant) {
        RoostButtonVariant.primary => RoostColors.accent, // gradient overrides
        RoostButtonVariant.secondary => RoostColors.surface2,
        RoostButtonVariant.ghost => Colors.transparent,
        RoostButtonVariant.destructive => Colors.transparent,
      };

  Color get _fg => switch (widget.variant) {
        RoostButtonVariant.primary => RoostColors.onAccent,
        RoostButtonVariant.secondary => RoostColors.textPrimary,
        RoostButtonVariant.ghost => RoostColors.textSecondary,
        RoostButtonVariant.destructive => RoostColors.negative,
      };

  BorderSide get _border => switch (widget.variant) {
        RoostButtonVariant.secondary => BorderSide(color: RoostColors.borderDefault, width: 0.5),
        RoostButtonVariant.destructive => BorderSide(color: RoostColors.negative, width: 0.5),
        _ => BorderSide.none,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        duration: RoostMotion.micro,
        scale: _pressed ? 0.97 : 1.0,
        child: AnimatedOpacity(
          duration: RoostMotion.micro,
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            height: RoostHeights.button,
            padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.xl),
            decoration: ShapeDecoration(
              color: _isPrimary ? null : _bg,
              gradient: _isPrimary ? RoostGradients.accent : null,
              shadows: _isPrimary && !disabled ? RoostShadows.ctaGlow : null,
              shape: SmoothRectangleBorder(
                side: _border,
                borderRadius: SmoothBorderRadius(
                  cornerRadius: RoostRadius.md,
                  cornerSmoothing: RoostRadius.squircleSmoothing,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: _fg),
                        const SizedBox(width: RoostSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _fg, fontSize: 16, fontWeight: FontWeight.w600,
                            letterSpacing: -0.16,
                          ),
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
