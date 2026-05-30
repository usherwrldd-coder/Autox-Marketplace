import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String coins(int amount) {
    return '${NumberFormat('#,###').format(amount)} AXC';
  }

  static String usd(int coins, {double rate = 1.0}) {
    return '\$${NumberFormat('#,###.00').format(coins * rate)}';
  }

  static String date(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);
  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
  static String dateTime(DateTime dt) => DateFormat('MMM d, yyyy • h:mm a').format(dt);

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    if (diff.inDays < 30)     return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365)    return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String auctionTimer(Duration remaining) {
    if (remaining.isNegative) return 'Ended';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (h > 24) return '${(h / 24).floor()}d ${h % 24}h';
    if (h > 0)  return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
    return '${_pad(m)}:${_pad(s)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String slug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  static String orderStatus(String status) {
    switch (status) {
      case 'pending':    return 'Pending';
      case 'in_escrow':  return 'In Escrow';
      case 'shipped':    return 'Shipped';
      case 'delivered':  return 'Delivered';
      case 'disputed':   return 'Disputed';
      case 'refunded':   return 'Refunded';
      case 'cancelled':  return 'Cancelled';
      default:           return status;
    }
  }
}
