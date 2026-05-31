import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/widgets/coin_badge.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'deposit_history_page.dart';

final walletProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user   = client.auth.currentUser;
  if (user == null) return null;
  return await client.from('wallets').select().eq('user_id', user.id).single();
});

final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user   = client.auth.currentUser;
  if (user == null) return [];
  return await client.from('transactions')
      .select().eq('user_id', user.id)
      .order('created_at', ascending: false).limit(50);
});

final bankSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('marketplace_settings')
      .select('key,value')
      .inFilter('key', ['bank_name','bank_account_number','bank_routing_number','bank_account_name','bank_swift','deposit_instructions']);
  final data = response as List;
  if (data.isEmpty) return {};
  final result = <String, String>{};
  for (final item in data) {
    if (item is Map) {
      final key = item['key'] as String?;
      final value = item['value'] as String?;
      if (key != null && value != null) {
        result[key] = value.replaceAll(RegExp(r'^"|"$'), '');
      }
    }
  }
  return result;
});

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});
  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  XFile? _proofFile;
  bool _processing = false;

  static const List<int> _quickAmounts = [500, 1000, 2500, 5000];

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _proofFile = file);
    }
  }

  Future<void> _handleSubmitDeposit() async {
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null || amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum deposit is 10 AXC')),
      );
      return;
    }
    if (_refCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reference number')),
      );
      return;
    }
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload proof of payment')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Upload proof
      final ext = _proofFile!.path.split('.').last;
      final fileName = 'deposit_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final fileBytes = await _proofFile!.readAsBytes();

      final storageResponse = await client.storage
          .from('deposit-proofs')
          .uploadBinary(fileName, Uint8List.fromList(fileBytes));

      // uploadBinary returns the path as a String on success
      final proofUrl = storageResponse;

      // Create deposit record
      final depositResponse = await client.from('deposits').insert({
        'user_id': user.id,
        'amount': amount,
        'reference_number': _refCtrl.text.trim(),
        'proof_url': proofUrl,
        'status': 'pending',
      });

      if (depositResponse is Map && (depositResponse['error'] != null)) {
        throw Exception('Failed to submit deposit: ${depositResponse['error']}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deposit submitted! Awaiting admin verification.'),
          backgroundColor: AppTheme.colorGreen,
        ),
      );

      // Clear form
      setState(() {
        _amountCtrl.clear();
        _refCtrl.clear();
        _proofFile = null;
      });

      ref.invalidate(walletProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorRed),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync     = ref.watch(transactionsProvider);
    final bankAsync   = ref.watch(bankSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MY WALLET')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance cards
              walletAsync.when(
                data: (wallet) => _buildBalanceCards(wallet),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),

              // Deposit & history row
              LayoutBuilder(builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDepositCard(bankAsync)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTransactionHistory(txAsync)),
                    ],
                  );
                }
                return Column(children: [
                  _buildDepositCard(bankAsync),
                  const SizedBox(height: 24),
                  _buildTransactionHistory(txAsync),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCards(Map<String, dynamic>? wallet) {
    final balance  = wallet?['balance']         as int? ?? 0;
    final escrow   = wallet?['escrow_balance']  as int? ?? 0;
    final spent    = wallet?['lifetime_spent']  as int? ?? 0;

    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2,
      children: [
        _balanceCard('Available Balance', balance, AppTheme.goldPrimary, '🪙'),
        _balanceCard('In Escrow',         escrow,  AppTheme.colorPurple, '🛡️'),
        _balanceCard('Total Spent',       spent,   AppTheme.colorGreen,  '🛒'),
      ],
    );
  }

  Widget _balanceCard(String label, int amount, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} AXC',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
    );
  }

  Widget _buildDepositCard(AsyncValue<Map<String, String>> bankAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DEPOSIT FUNDS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DepositHistoryPage()),
                  );
                },
              ),
            ],
          ),

          // Bank details
          bankAsync.when(
            data: (bank) => _buildBankDetails(bank),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (_, e) => Text('Error loading bank details: $e'),
          ),
          const SizedBox(height: 20),

          // Trust messaging
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.colorBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.colorBlue.withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛡️ Secure Deposit Process', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.colorBlue)),
                SizedBox(height: 4),
                Text('• Transfer funds directly to our verified bank account', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text('• All deposits are manually verified before crediting', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text('• Never send payments directly to vendors outside the platform', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text('• All marketplace transactions must remain within AUTOX for escrow protection', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('DEPOSIT FORM', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          // Quick amounts
          const Text('QUICK SELECT', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5,
            children: _quickAmounts.map((a) => _quickAmountBtn(a)).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Custom Amount (min. 10 AXC)', prefixIcon: Icon(Icons.toll)),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _refCtrl,
            decoration: const InputDecoration(labelText: 'Bank Reference Number *', prefixIcon: Icon(Icons.receipt_long),
              hintText: 'Enter the reference/transaction ID from your bank transfer'),
          ),
          const SizedBox(height: 16),

          // Proof upload
          InkWell(
            onTap: _pickProof,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _proofFile != null ? AppTheme.goldPrimary : AppTheme.borderColor),
                borderRadius: BorderRadius.circular(10),
                color: _proofFile != null ? AppTheme.goldPrimary.withOpacity(0.05) : AppTheme.bgCard,
              ),
              child: Row(
                children: [
                  Icon(_proofFile != null ? Icons.check_circle : Icons.upload_file,
                    color: _proofFile != null ? AppTheme.goldPrimary : AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_proofFile != null ? 'Proof uploaded: ${_proofFile!.name}' : 'Upload Proof of Payment *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                          color: _proofFile != null ? AppTheme.goldPrimary : AppTheme.textPrimary)),
                      Text(_proofFile != null ? 'Tap to change' : 'Image or PDF of your bank transfer receipt',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
            ),
            child: const Text('💡 1 AXC = \$1.00 USD · Funds credited after admin verification',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 16),

          GradientButton(
            label: 'Submit Deposit',
            onPressed: _handleSubmitDeposit,
            isLoading: _processing,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails(Map<String, String> bank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BANK ACCOUNT DETAILS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
          const SizedBox(height: 12),
          _bankRow('Bank Name', bank['bank_name'] ?? '—'),
          _bankRow('Account Name', bank['bank_account_name'] ?? '—'),
          _bankRow('Account Number', bank['bank_account_number'] ?? '—'),
          _bankRow('Routing Number', bank['bank_routing_number'] ?? '—'),
          if (bank['bank_swift'] != null && bank['bank_swift']!.isNotEmpty)
            _bankRow('SWIFT/BIC', bank['bank_swift']!),
          const SizedBox(height: 8),
          Text(bank['deposit_instructions'] ?? 'Transfer the exact amount and upload proof.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        ],
      ),
    );
  }

  Widget _quickAmountBtn(int amount) {
    final selected = _amountCtrl.text == amount.toString();
    return GestureDetector(
      onTap: () => setState(() => _amountCtrl.text = amount.toString()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppTheme.goldPrimary.withOpacity(0.1) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.goldPrimary : AppTheme.borderColor),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} AXC',
            style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppTheme.goldPrimary : AppTheme.textPrimary, fontSize: 13)),
          Text('\$$amount', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
      ),
    );
  }

  Widget _buildTransactionHistory(AsyncValue<List<Map<String, dynamic>>> txAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TRANSACTION HISTORY', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        txAsync.when(
          data: (txs) => txs.isEmpty
              ? const Center(child: Text('No transactions yet', style: TextStyle(color: AppTheme.textMuted)))
              : Column(children: txs.take(20).map(_buildTxRow).toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ]),
    );
  }

  Widget _buildTxRow(Map<String, dynamic> tx) {
    final type    = tx['type'] as String;
    final amount  = tx['amount'] as int;
    final isCredit = ['topup', 'escrow_release', 'refund'].contains(type);
    final icon    = type == 'topup' ? '⬆️' : type == 'escrow_release' ? '🛡️' : type == 'refund' ? '↩️' : '🛒';
    final color   = isCredit ? AppTheme.colorGreen : AppTheme.colorRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx['description'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Text('${isCredit ? "+" : "-"}${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} AXC',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }
}