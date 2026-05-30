import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final double fontSize;

  const VerifiedBadge({
    super.key,
    this.label    = 'Verified',
    this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.colorGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: fontSize + 2, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: fontSize, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class EscrowBadge extends StatelessWidget {
  const EscrowBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.colorPurple.withOpacity(0.08), AppTheme.colorBlue.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colorPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Escrow Protected', style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.colorPurple, fontSize: 13,
                )),
                const SizedBox(height: 2),
                const Text(
                  'Coins are held securely until you confirm delivery.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
