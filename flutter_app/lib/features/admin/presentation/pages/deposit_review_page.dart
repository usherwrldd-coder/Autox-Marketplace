import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/widgets/gradient_button.dart';

final pendingDepositsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('deposits')
      .select('''
        id,
        user_id,
        amount,
        reference_number,
        proof_url,
        status,
        created_at,
        profiles (id, username, full_name, email)
      ''')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return (response as List).cast<Map<String, dynamic>>();
});

final processedDepositsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('deposits')
      .select('''
        id,
        user_id,
        amount,
        reference_number,
        status,
        rejection_reason,
        reviewed_by,
        created_at,
        profiles (id, username, full_name, email)
      ''')
      .inFilter('status', ['approved', 'rejected'])
      .order('created_at', ascending: false)
      .limit(50);
  return (response as List).cast<Map<String, dynamic>>();
});

class DepositReviewPage extends ConsumerStatefulWidget {
  const DepositReviewPage({super.key});

  @override
  ConsumerState<DepositReviewPage> createState() => _DepositReviewPageState();
}

class _DepositReviewPageState extends ConsumerState<DepositReviewPage> {
  String _tab = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEPOSIT REVIEW'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 'pending'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tab == 'pending' ? AppTheme.goldPrimary.withOpacity(0.15) : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _tab == 'pending' ? AppTheme.goldPrimary : AppTheme.borderColor,
                        ),
                      ),
                      child: Center(
                        child: Text('⏳ Pending (${ref.watch(pendingDepositsProvider).value?.length ?? 0})',
                          style: TextStyle(
                            fontWeight: _tab == 'pending' ? FontWeight.w700 : FontWeight.w400,
                            color: _tab == 'pending' ? AppTheme.goldPrimary : AppTheme.textMuted,
                          )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 'processed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tab == 'processed' ? AppTheme.goldPrimary.withOpacity(0.15) : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _tab == 'processed' ? AppTheme.goldPrimary : AppTheme.borderColor,
                        ),
                      ),
                      child: Center(
                        child: Text('✅ Processed',
                          style: TextStyle(
                            fontWeight: _tab == 'processed' ? FontWeight.w700 : FontWeight.w400,
                            color: _tab == 'processed' ? AppTheme.goldPrimary : AppTheme.textMuted,
                          )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 'pending'
                ? _buildPendingList()
                : _buildProcessedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    return ref.watch(pendingDepositsProvider).when(
      data: (deposits) {
        if (deposits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppTheme.colorGreen),
                SizedBox(height: 16),
                Text('All caught up!', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                SizedBox(height: 8),
                Text('No pending deposits to review', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: deposits.length,
          itemBuilder: (ctx, i) => _PendingDepositCard(deposit: deposits[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildProcessedList() {
    return ref.watch(processedDepositsProvider).when(
      data: (deposits) {
        if (deposits.isEmpty) {
          return const Center(
            child: Text('No processed deposits', style: TextStyle(color: AppTheme.textMuted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: deposits.length,
          itemBuilder: (ctx, i) => _ProcessedDepositCard(deposit: deposits[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PendingDepositCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> deposit;
  const _PendingDepositCard({required this.deposit});

  @override
  ConsumerState<_PendingDepositCard> createState() => _PendingDepositCardState();
}

class _PendingDepositCardState extends ConsumerState<_PendingDepositCard> {
  final _reasonCtrl = TextEditingController();
  bool _processing = false;
  String? _action; // 'approve' or 'reject'
  bool _showReason = false;

  Future<void> _submitAction() async {
    if (_action == 'reject' && _reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rejection reason')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final functionName = _action == 'approve' ? 'approve-deposit' : 'reject-deposit';
      final body = <String, dynamic>{'deposit_id': widget.deposit['id']};
      if (_action == 'reject') body['reason'] = _reasonCtrl.text.trim();

      final response = await client.functions.invoke(functionName, body: body);

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Action failed');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_action == 'approve' ? 'Deposit approved & credited!' : 'Deposit rejected'),
          backgroundColor: _action == 'approve' ? AppTheme.colorGreen : AppTheme.colorRed,
        ),
      );

      // Refresh data
      ref.invalidate(pendingDepositsProvider);
      ref.invalidate(processedDepositsProvider);

      setState(() {
        _processing = false;
        _action = null;
        _showReason = false;
        _reasonCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorRed),
      );
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.deposit['amount'] as int? ?? 0;
    final refNum = widget.deposit['reference_number'] as String? ?? 'N/A';
    final proofUrl = widget.deposit['proof_url'] as String? ?? '';
    final createdAt = widget.deposit['created_at'] as String? ?? '';
    final date = createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;
    final profile = widget.deposit['profiles'] as Map? ?? {};
    final username = profile['username'] as String? ?? 'Unknown';
    final fullName = profile['full_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} AXC',
                    style: const TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
                  const SizedBox(height: 4),
                  Text('Ref: $refNum', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('⏳ Pending', style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(fullName ?? username, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          if (proofUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // In production, open image viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proof URL: Opens in image viewer')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colorBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.colorBlue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.image, size: 16, color: AppTheme.colorBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('View proof of payment', style: TextStyle(fontSize: 12, color: AppTheme.colorBlue, fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: AppTheme.colorBlue),
                  ],
                ),
              ),
            ),
          ],
          if (_showReason) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _action == 'reject' ? 'Rejection reason *' : 'Note (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _action == null
              ? Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: '✅ Approve',
                        onPressed: () {
                          setState(() {
                            _action = 'approve';
                            _showReason = true;
                          });
                        },
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _action = 'reject';
                            _showReason = true;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.colorRed,
                          side: const BorderSide(color: AppTheme.colorRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('❌ Reject'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: _processing ? 'Processing...' : 'Confirm ${_action == 'approve' ? 'Approval' : 'Rejection'}',
                        onPressed: _processing ? null : _submitAction,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _action = null;
                          _showReason = false;
                          _reasonCtrl.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }
}

class _ProcessedDepositCard extends StatelessWidget {
  final Map<String, dynamic> deposit;
  const _ProcessedDepositCard({required this.deposit});

  @override
  Widget build(BuildContext context) {
    final amount = deposit['amount'] as int? ?? 0;
    final refNum = deposit['reference_number'] as String? ?? 'N/A';
    final status = deposit['status'] as String? ?? 'approved';
    final reason = deposit['rejection_reason'] as String?;
    final createdAt = deposit['created_at'] as String? ?? '';
    final date = createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;
    final profile = deposit['profiles'] as Map? ?? {};
    final username = profile['username'] as String? ?? 'Unknown';

    final isApproved = status == 'approved';
    final color = isApproved ? AppTheme.colorGreen : AppTheme.colorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} AXC',
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isApproved ? '✅ Approved' : '❌ Rejected',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ref: $refNum · $username · $date', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reason: $reason', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}