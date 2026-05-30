import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

final buyerOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user   = client.auth.currentUser;
  if (user == null) return [];
  final svc = ref.watch(supabaseServiceProvider);
  return svc.fetchBuyerOrders(user.id);
});

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  Color _statusColor(String status) => switch (status) {
    'in_escrow'  => AppTheme.colorPurple,
    'shipped'    => AppTheme.colorBlue,
    'delivered'  => AppTheme.colorGreen,
    'disputed'   => AppTheme.colorRed,
    'refunded'   => AppTheme.goldPrimary,
    'cancelled'  => AppTheme.textMuted,
    _            => AppTheme.textMuted,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('MY ORDERS')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet', style: TextStyle(color: AppTheme.textMuted)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (ctx, i) => _OrderCard(order: orders[i], statusColor: _statusColor, ref: ref),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.colorRed))),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color Function(String) statusColor;
  final WidgetRef ref;
  const _OrderCard({required this.order, required this.statusColor, required this.ref});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final color  = statusColor(status);
    final total  = order['total_coins'] as int? ?? 0;
    final orderNum = order['order_number'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order['products']?['title'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text('$orderNum · ${order['created_at']?.toString().substring(0, 10) ?? ""}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Text('${total.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} AXC',
                style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
              if (status == 'shipped')
              ElevatedButton(
                onPressed: () async {
                  try {
                    final client = ref.read(supabaseClientProvider);
                    // Update order status to delivered and release escrow
                    await client.from('orders')
                        .update({'status': 'delivered', 'delivered_at': DateTime.now().toIso8601String()})
                        .eq('id', order['id']);
                    ref.invalidate(buyerOrdersProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery confirmed! Escrow will be released.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Confirm Delivery'),
              ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 12)),
              child: const Text('Track Order'),
            ),
            if (['in_escrow', 'shipped'].contains(status)) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Request Refund'),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
