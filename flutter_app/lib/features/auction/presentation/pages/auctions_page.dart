import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/widgets/auction_timer.dart';

final auctionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await client.from('products')
      .select('*, vendor_profiles(shop_name, is_verified)')
      .eq('is_auction', true)
      .eq('is_active', true)
      .eq('is_approved', true)
      .gte('auction_end', DateTime.now().toIso8601String())
      .order('auction_end', ascending: true)
      .limit(48);
});

class AuctionsPage extends ConsumerWidget {
  const AuctionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(auctionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('LIVE AUCTIONS'),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.colorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.colorRed.withOpacity(0.4))),
            child: const Text('● LIVE', style: TextStyle(fontSize: 11, color: AppTheme.colorRed, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      body: auctionsAsync.when(
        data: (auctions) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
          ),
          itemCount: auctions.length,
          itemBuilder: (ctx, i) => _AuctionCard(product: auctions[i], ref: ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AuctionCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final WidgetRef ref;
  const _AuctionCard({required this.product, required this.ref});
  @override
  State<_AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<_AuctionCard> {
  final _bidCtrl = TextEditingController();
  bool _placing  = false;

  Future<void> _placeBid() async {
    final amount = int.tryParse(_bidCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _placing = true);
    try {
      final client = widget.ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Please login to place bids');
      final productId = widget.product['id'];
      // Create bid record
      final response = await client.from('bids').insert({
        'product_id': productId,
        'bidder_id': user.id,
        'bid_amount': amount,
        'status': 'active',
        'is_winning': false,
      });
      if (response is Map && response['error'] != null) {
        throw Exception(response['error']);
      }
      widget.ref.invalidate(auctionsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed! ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorRed));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() { _bidCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p          = widget.product;
    final auctionEnd = p['auction_end'] != null ? DateTime.parse(p['auction_end']) : DateTime.now().add(const Duration(hours: 2));
    final currentBid = p['current_bid'] as int? ?? p['price_coins'] as int? ?? 0;
    final bidCount   = p['bid_count'] as int? ?? 0;
    final minBid     = currentBid + 50;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 130, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A0A00), Color(0xFF0F1F3D)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(children: [
              const Center(child: Text('⚙️', style: TextStyle(fontSize: 56))),
              Positioned(top: 10, right: 10, child: AuctionTimer(endTime: auctionEnd)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['brand'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(p['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Current Bid', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Text('${currentBid.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} AXC',
                    style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$bidCount bids', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const Text('You\'re outbid', style: TextStyle(fontSize: 10, color: AppTheme.colorRed)),
                ]),
              ]),
              // Progress bar
              const SizedBox(height: 8),
              Container(height: 3, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.6,
                  child: Container(decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(2))))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _bidCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(hintText: 'Min $minBid AXC', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _placing ? null : _placeBid,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), textStyle: const TextStyle(fontSize: 12)),
                  child: _placing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Bid'),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
