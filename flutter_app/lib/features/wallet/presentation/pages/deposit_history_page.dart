import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

final depositsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];
  final response = await client
      .from('deposits')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return (response as List).cast<Map<String, dynamic>>();
});

class DepositHistoryPage extends ConsumerWidget {
  const DepositHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(depositsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEPOSIT HISTORY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: depositsAsync.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text('No deposits yet', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                  SizedBox(height: 8),
                  Text('Submit a deposit to fund your wallet', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deposits.length,
            itemBuilder: (ctx, i) => _DepositCard(deposit: deposits[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final Map<String, dynamic> deposit;

  const _DepositCard({required this.deposit});

  Color get _statusColor {
    final status = deposit['status'] as String? ?? 'pending';
    switch (status) {
      case 'approved': return AppTheme.colorGreen;
      case 'rejected': return AppTheme.colorRed;
      default: return AppTheme.goldPrimary;
    }
  }

  String get _statusLabel {
    final status = deposit['status'] as String? ?? 'pending';
    switch (status) {
      case 'approved': return '✅ Approved';
      case 'rejected': return '❌ Rejected';
      default: return '⏳ Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = deposit['amount'] as int? ?? 0;
    final ref = deposit['reference_number'] as String? ?? 'N/A';
    final status = deposit['status'] as String? ?? 'pending';
    final reason = deposit['rejection_reason'] as String?;
    final createdAt = deposit['created_at'] as String? ?? '';
    final date = createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} AXC',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel, style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('Ref: $ref', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          if (status == 'rejected' && reason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.colorRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.colorRed.withOpacity(0.2)),
              ),
              child: Text('Reason: $reason', style: const TextStyle(fontSize: 11, color: AppTheme.colorRed)),
            ),
          ],
        ],
      ),
    );
  }
}