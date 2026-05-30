import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AuctionTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;
  final VoidCallback? onExpired;

  const AuctionTimer({
    super.key,
    required this.endTime,
    this.style,
    this.onExpired,
  });

  @override
  State<AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<AuctionTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer t) {
    final remaining = widget.endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      t.cancel();
      widget.onExpired?.call();
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining.inHours < 1;
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    final label = h > 0 ? '${_pad(h)}:${_pad(m)}:${_pad(s)}' : '${_pad(m)}:${_pad(s)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        (isUrgent ? AppTheme.colorRed : AppTheme.colorBlue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: (isUrgent ? AppTheme.colorRed : AppTheme.colorBlue).withOpacity(0.3)),
      ),
      child: Text(
        '⏱ $label',
        style: widget.style ?? TextStyle(
          fontFamily:  'Orbitron',
          fontSize:    12,
          fontWeight:  FontWeight.w700,
          color:       isUrgent ? AppTheme.colorRed : AppTheme.colorBlue,
        ),
      ),
    );
  }
}
