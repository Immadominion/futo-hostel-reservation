import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The one input primitive — a squircle field that rings accent on focus.
class RoostTextField extends StatefulWidget {
  const RoostTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.action,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final TextInputAction? action;
  final bool autofocus;

  @override
  State<RoostTextField> createState() => _RoostTextFieldState();
}

class _RoostTextFieldState extends State<RoostTextField> {
  final _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: RoostHeights.input,
      padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.lg),
      decoration: ShapeDecoration(
        color: RoostColors.surfaceInput,
        shape: SmoothRectangleBorder(
          side: BorderSide(
            color: _focused ? RoostColors.accent : RoostColors.borderDefault,
            width: _focused ? 1.4 : 0.5,
          ),
          borderRadius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: RoostRadius.squircleSmoothing),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: _focused ? RoostColors.accent : RoostColors.textTertiary),
            const SizedBox(width: RoostSpacing.md),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.action,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: RoostColors.accent,
              style: TextStyle(fontSize: 15, color: RoostColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(fontSize: 15, color: RoostColors.textTertiary, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );
  }
}
