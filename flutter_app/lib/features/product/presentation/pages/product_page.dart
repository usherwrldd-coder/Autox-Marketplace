import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/verified_badge.dart';
import '../../../../shared/widgets/auction_timer.dart';

final productDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, slug) async {
  final svc = ref.watch(supabaseServiceProvider);
  return svc.fetchProductBySlug(slug);
});

class ProductPage extends ConsumerStatefulWidget {
  final String slug;
  const ProductPage({super.key, required this.slug});
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int    _qty          = 1;
  bool   _wishlisted   = false;
  bool   _purchasing   = false;
  bool   _showCheckout = false;
  String _offerAmount  = '';
  int    _selectedImg  = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _buyNow(Map<String, dynamic> product) async {
    final wallet = await ref.read(supabaseServiceProvider).fetchWallet(
      ref.read(supabaseClientProvider).auth.currentUser!.id,
    );
    final balance = wallet?['balance'] as int? ?? 0;
    final total   = (product['price_coins'] as int) * _qty + 150;

    if (balance < total) {
      context.push('/wallet');
      return;
    }
    setState(() => _showCheckout = true);
  }

  Future<void> _confirmPurchase(Map<String, dynamic> product) async {
    setState(() { _purchasing = true; _showCheckout = false; });
    try {
      final client = ref.read(supabaseClientProvider);
      final user   = client.auth.currentUser!;
      await client.from('orders').insert({
        'buyer_id':   user.id,
        'vendor_id':  product['vendor_id'],
        'product_id': product['id'],
        'quantity':   _qty,
        'unit_price': product['price_coins'],
        'shipping_cost': 150,
        'platform_fee':  ((product['price_coins'] as int) * 0.035).floor(),
        'total_coins':   (product['price_coins'] as int) * _qty + 150,
        'status':        'in_escrow',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed! Coins held in escrow. ✓'), backgroundColor: AppTheme.colorGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorRed));
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: productAsync.when(
        data: (product) => product == null
            ? const Center(child: Text('Product not found'))
            : Stack(
                children: [
                  _buildBody(product),
                  if (_showCheckout) _buildCheckoutOverlay(product),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> product) {
    final images     = (product['images'] as List?)?.cast<String>() ?? [];
    final priceCoins = product['price_coins'] as int? ?? 0;
    final isAuction  = product['is_auction'] as bool? ?? false;
    final auctionEnd = product['auction_end'] != null ? DateTime.parse(product['auction_end']) : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 440, child: _buildImageSection(images)),
                  const SizedBox(width: 32),
                  Expanded(child: _buildInfoSection(product, priceCoins, isAuction, auctionEnd)),
                ])
              : Column(children: [
                  _buildImageSection(images),
                  const SizedBox(height: 24),
                  _buildInfoSection(product, priceCoins, isAuction, auctionEnd),
                ]);
        }),
      ),
    );
  }

  Widget _buildImageSection(List<String> images) => Column(children: [
    Container(
      height: 300, width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0A00), Color(0xFF0F1F3D)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: images.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(images[_selectedImg], fit: BoxFit.cover))
          : const Center(child: Text('⚙️', style: TextStyle(fontSize: 80))),
    ),
    if (images.length > 1) ...[
      const SizedBox(height: 10),
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _selectedImg = i),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: i == _selectedImg ? AppTheme.goldPrimary : AppTheme.borderColor, width: i == _selectedImg ? 2 : 1),
                image: DecorationImage(image: NetworkImage(images[i]), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    ],
  ]);

  Widget _buildInfoSection(Map<String, dynamic> product, int priceCoins, bool isAuction, DateTime? auctionEnd) {
    final title      = product['title'] as String? ?? '';
    final brand      = product['brand'] as String? ?? '';
    final vehicleMake  = product['vehicle_make'] as String? ?? '';
    final vehicleModel = product['vehicle_model'] as String? ?? '';
    final currentBid   = product['current_bid'] as int?;
    final bidCount     = product['bid_count'] as int? ?? 0;
    final avgRating    = (product['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount  = product['review_count'] as int? ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Badges
      Wrap(spacing: 8, children: [
        const VerifiedBadge(label: 'Verified Part'),
        if (product['is_featured'] == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4))),
            child: const Text('★ Featured', style: TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
          ),
        const EscrowBadge(),
      ]),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 22, fontWeight: FontWeight.w700, height: 1.2)),
      const SizedBox(height: 8),
      Text('$brand • Compatible: $vehicleMake $vehicleModel', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      // Rating
      Row(children: [
        ...List.generate(5, (i) => Icon(i < avgRating.floor() ? Icons.star : Icons.star_border, size: 14, color: AppTheme.goldLight)),
        const SizedBox(width: 6),
        Text('$avgRating ($reviewCount reviews)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 16),
      // Price / Bid
      if (isAuction && auctionEnd != null) ...[
        Row(children: [AuctionTimer(endTime: auctionEnd), const SizedBox(width: 10), Text('$bidCount bids', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))]),
        const SizedBox(height: 8),
        Text('Current Bid', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ] else
        const Text('Price', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      Text('${(currentBid ?? priceCoins).toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} AXC',
        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
      Text('\$${(currentBid ?? priceCoins)} USD', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      const SizedBox(height: 20),
      // Quantity selector
      if (!isAuction) ...[
        Row(children: [
          const Text('Qty:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderColor)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 99))),
              Text('$_qty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => setState(() => _qty = (_qty + 1).clamp(1, 99))),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
      ],
      // CTAs
      Row(children: [
        Expanded(child: GradientButton(
          label: isAuction ? 'Place Bid' : 'Buy Now — ${((currentBid ?? priceCoins) * _qty + 150).toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} AXC',
          onPressed: _purchasing ? null : () => _buyNow(product),
          isLoading: _purchasing,
          width: double.infinity,
        )),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(_wishlisted ? Icons.favorite : Icons.favorite_border, color: _wishlisted ? AppTheme.colorRed : AppTheme.textMuted),
          onPressed: () => setState(() => _wishlisted = !_wishlisted),
          style: IconButton.styleFrom(backgroundColor: AppTheme.bgCard, side: const BorderSide(color: AppTheme.borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
      const SizedBox(height: 12),
      // Offer input (negotiable)
      if (product['is_negotiable'] == true) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💬 Make an Offer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.colorBlue)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                onChanged: (v) => _offerAmount = v,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Offer amount in AXC...', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              )),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Send')),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      // Tabs
      Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
        child: TabBar(controller: _tabs, labelColor: AppTheme.goldPrimary, unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.goldPrimary, tabs: const [Tab(text: 'Details'), Tab(text: 'Reviews'), Tab(text: 'Shipping'), Tab(text: 'Vendor')]),
      ),
      SizedBox(
        height: 200,
        child: TabBarView(controller: _tabs, children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: Text(product['description'] ?? 'No description available.', style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.7))),
          const Center(child: Text('Reviews loaded from database.', style: TextStyle(color: AppTheme.textMuted))),
          const Padding(padding: EdgeInsets.only(top: 16), child: Text('Shipping options shown here.', style: TextStyle(color: AppTheme.textMuted))),
          Padding(padding: const EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['vendor_profiles']?['shop_name'] ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (product['vendor_profiles']?['is_verified'] == true) ...[const SizedBox(height: 6), const VerifiedBadge()],
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildCheckoutOverlay(Map<String, dynamic> product) {
    final priceCoins = product['price_coins'] as int? ?? 0;
    final total      = priceCoins * _qty + 150;
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderColor)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('CONFIRM ORDER', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ...[
                ('Product', product['title'] as String? ?? '', false),
                ('Quantity', '$_qty', false),
                ('Subtotal', '${priceCoins * _qty} AXC', false),
                ('Shipping', '150 AXC', false),
                ('Total',    '$total AXC', true),
              ].map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r.$1, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  Text(r.$2, style: TextStyle(fontWeight: r.$3 ? FontWeight.w700 : FontWeight.w500, color: r.$3 ? AppTheme.goldPrimary : AppTheme.textPrimary, fontSize: r.$3 ? 15 : 13)),
                ]),
              )),
              const Divider(height: 24),
              const EscrowBadge(),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GradientButton(label: 'Confirm · $total AXC', onPressed: _purchasing ? null : () => _confirmPurchase(product), isLoading: _purchasing, width: double.infinity)),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: () => setState(() => _showCheckout = false), child: const Text('Cancel')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
