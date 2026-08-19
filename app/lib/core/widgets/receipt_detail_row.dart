import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A stable two-column row for receipts. Labels have a fixed column and every
/// value starts on the same vertical line. Long identifiers shrink in place
/// instead of wrapping and breaking the receipt rhythm.
class ReceiptDetailRow extends StatelessWidget {
  const ReceiptDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = constraints.maxWidth < 340 ? 126.0 : 150.0;
          final valueStyle = TextStyle(
            fontSize: strong ? 15 : 13.5,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? RoostColors.accent : RoostColors.textPrimary,
            fontFamily: mono ? 'monospace' : 'Montserrat',
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: RoostColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: RoostSpacing.md),
              Expanded(
                child: Semantics(
                  label: '$label: $value',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: valueStyle,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
