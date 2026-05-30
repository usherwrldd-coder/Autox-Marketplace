import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CoinBadge extends StatelessWidget {
  final int amount;
  final double fontSize;
  final bool showUsd;
  final Color? color;

  const CoinBadge({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.showUsd  = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪙 ', style: TextStyle(fontSize: fontSize * 0.85)),
            Text(
              '${amount.toLocaleString()} AXC',
              style: TextStyle(
                fontFamily:  'Orbitron',
                fontSize:    fontSize,
                fontWeight:  FontWeight.w700,
                color:       color ?? AppTheme.goldPrimary,
              ),
            ),
          ],
        ),
        if (showUsd)
          Text(
            '\$${amount.toLocaleString()} USD',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
      ],
    );
  }
}

extension IntFormat on int {
  String toLocaleString() {
    final s = toString();
    final buffer = StringBuffer();
    final start  = s.length % 3;
    if (start > 0) buffer.write(s.substring(0, start));
    for (var i = start; i < s.length; i += 3) {
      if (buffer.isNotEmpty) buffer.write(',');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }
}
