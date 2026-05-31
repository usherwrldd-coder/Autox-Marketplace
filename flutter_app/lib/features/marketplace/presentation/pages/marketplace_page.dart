import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/navbar.dart';

// Mock products data (fallback when Supabase is not available)
const mockProducts = [
  {'id': '1', 'title': 'Brembo GT 6-Piston Brake Kit', 'brand': 'Brembo', 'price': 2800.0, 'images': ['https://images.unsplash.com/photo-1616400619175-5beda3a17896?w=400'], 'rating': 4.9, 'reviews': 234, 'vendor': 'ProBrake Co.', 'type': 'buy_now', 'badge': 'Featured'},
  {'id': '2', 'title': 'HKS GT2 Supercharger System', 'brand': 'HKS', 'price': 4200.0, 'images': ['https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400'], 'rating': 4.8, 'reviews': 156, 'vendor': 'JDM Direct', 'type': 'auction', 'badge': 'Hot'},
  {'id': '3', 'title': 'BC Racing Coilover Kit Type BR', 'brand': 'BC Racing', 'price': 1200.0, 'images': ['https://images.unsplash.com/photo-1626814026160-2237a95fc5a0?w=400'], 'rating': 4.7, 'reviews': 412, 'vendor': 'Track Ready', 'type': 'negotiable', 'badge': 'Best Seller'},
  {'id': '4', 'title': 'Akrapovič Evolution Exhaust Ti', 'brand': 'Akrapovič', 'price': 3600.0, 'images': ['https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400'], 'rating': 5.0, 'reviews': 89, 'vendor': 'EU Performance', 'type': 'buy_now', 'badge': 'Premium'},
  {'id': '5', 'title': 'Recaro Pole Position Seat', 'brand': 'Recaro', 'price': 1800.0, 'images': ['https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=400'], 'rating': 4.9, 'reviews': 201, 'vendor': 'Race Seats EU', 'type': 'buy_now', 'badge': 'New'},
  {'id': '6', 'title': 'Turbosmart BOV Kompact Dual', 'brand': 'Turbosmart', 'price': 320.0, 'images': ['https://images.unsplash.com/photo-1517524285303-d6fc683dddf8?w=400'], 'rating': 4.6, 'reviews': 567, 'vendor': 'Boost Kings', 'type': 'negotiable', 'badge': ''},
  {'id': '7', 'title': 'HID Motorsports Xenon Kit H7', 'brand': 'HID MS', 'price': 189.0, 'images': ['https://images.unsplash.com/photo-1493238792000-8113da705763?w=400'], 'rating': 4.5, 'reviews': 890, 'vendor': 'LuxLight', 'type': 'buy_now', 'badge': ''},
  {'id': '8', 'title': 'Bilstein B16 PSS10 Kit', 'brand': 'Bilstein', 'price': 1650.0, 'images': ['https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=400'], 'rating': 4.8, 'reviews': 178, 'vendor': 'German Parts', 'type': 'auction', 'badge': 'Ending Soon'},
];

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});
  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> with SingleTickerProviderStateMixin {
  String? _selectedType;
  String  _sortBy  = 'newest';
  final int     _page    = 1;
  late TabController _tabController;
  double _walletBalance = 2450.0;
  int _notifications = 3;
  
  Map<String, dynamic> get _filters => {
    'productType': _selectedType,
    'sortBy': _sortBy,
    'page': _page,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      switch (_tabController.index) {
        case 0: context.go('/'); break;
        case 1: // Already on marketplace
          break;
        case 2: context.go('/auctions'); break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Use mock data for now (Supabase may not be configured)
    final products = _getFilteredProducts();

    return Scaffold(
      body: Column(
        children: [
          // Navbar
          Navbar(
            currentPage: 'marketplace',
            walletBalance: _walletBalance,
            notifications: _notifications,
          ),
          
          // TabBar
          _buildTabBar(),
          
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar filters (desktop only)
                if (width > 768)
                  SizedBox(width: 240, child: _buildFilterSidebar()),

                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Toolbar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Type filter tabs
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _typeTab('All',       null),
                                    _typeTab('Buy Now',   'buy_now'),
                                    _typeTab('Auction',   'auction'),
                                    _typeTab('Negotiate', 'negotiable'),
                                  ],
                                ),
                              ),
                            ),
                            // Sort
                            DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: AppTheme.bgCard,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'newest',     child: Text('Newest', style: TextStyle(color: AppTheme.textPrimary))),
                                DropdownMenuItem(value: 'price_low',  child: Text('Price: Low-High', style: TextStyle(color: AppTheme.textPrimary))),
                                DropdownMenuItem(value: 'price_high', child: Text('Price: High-Low', style: TextStyle(color: AppTheme.textPrimary))),
                                DropdownMenuItem(value: 'rating',     child: Text('Top Rated', style: TextStyle(color: AppTheme.textPrimary))),
                              ],
                              onChanged: (v) => setState(() => _sortBy = v!),
                            ),
                          ],
                        ),
                      ),

                      // Products grid
                      Expanded(
                        child: products.isEmpty
                            ? const Center(child: Text('No products found', style: TextStyle(color: AppTheme.textMuted)))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 280, crossAxisSpacing: 16,
                                  mainAxisSpacing: 16, childAspectRatio: 0.75,
                                ),
                                itemCount: products.length,
                                itemBuilder: (ctx, i) {
                                  return _productCard(products[i]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    var filtered = mockProducts.where((p) {
      if (_selectedType != null && p['type'] != _selectedType) return false;
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'price_high':
        filtered.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'rating':
        filtered.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      default: // newest
        break;
    }

    return filtered;
  }

  Widget _productCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}'),
      child: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: product['images'] != null && (product['images'] as List).isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: (product['images'] as List).first,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                color: AppTheme.bgDark,
                                child: const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
                              ),
                              errorWidget: (ctx, url, error) => Container(
                                color: AppTheme.bgDark,
                                child: const Center(child: Icon(Icons.image_not_supported, color: AppTheme.textMuted, size: 48)),
                              ),
                            )
                          : Container(
                              color: AppTheme.bgDark,
                              child: const Center(child: Icon(Icons.build, size: 48, color: AppTheme.goldPrimary)),
                            ),
                    ),
                    // Badge
                    if (product['badge'] != null && (product['badge'] as String).isNotEmpty)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                          ),
                          child: Text(
                            product['badge'] as String,
                            style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    // Type badge
                    if (product['type'] == 'auction')
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.colorRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.colorRed.withOpacity(0.3)),
                          ),
                          child: const Text('🔨 Auction', style: TextStyle(fontSize: 10, color: AppTheme.colorRed, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else if (product['type'] == 'negotiable')
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.colorBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.colorBlue.withOpacity(0.3)),
                          ),
                          child: const Text('💬 Offer', style: TextStyle(fontSize: 10, color: AppTheme.colorBlue, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(product['brand'] ?? '').toString().toUpperCase()} · ${(product['type'] ?? '').toString().toUpperCase()}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['title'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < (product['rating'] as double).floor() ? Icons.star : Icons.star_border,
                          size: 12, color: AppTheme.goldLight,
                        )),
                        const SizedBox(width: 4),
                        Text('${product['rating']} (${product['reviews']})', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'AOC ${(product['price'] as double).toStringAsFixed(0)}',
                            style: GoogleFonts.orbitron(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/product/${product['id']}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(product['type'] == 'auction' ? 'Bid' : product['type'] == 'negotiable' ? 'Offer' : 'Buy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('🏪 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            product['vendor'] as String,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text('✓ Escrow', style: TextStyle(fontSize: 10, color: AppTheme.colorGreen)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.2), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.goldPrimary,
        indicatorWeight: 3,
        labelColor: AppTheme.goldPrimary,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: '🏠 HOME'),
          Tab(text: '🛒 MARKETPLACE'),
          Tab(text: '🔨 AUCTIONS'),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.bgDark, AppTheme.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(top: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _footerLink('About', '/about'),
              _footerLink('Help', '/help'),
              _footerLink('Terms', '/terms'),
              _footerLink('Privacy', '/privacy'),
              _footerLink('Contact', '/contact'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('© 2024 AUTOX Marketplace. All rights reserved.',
            style: TextStyle(fontSize: 12, color: AppTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label, String path) {
    return GestureDetector(
      onTap: () => context.push(path),
      child: Text(label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _typeTab(String label, String? value) {
    final selected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.goldPrimary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.goldPrimary : AppTheme.borderColor),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? AppTheme.goldPrimary : AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FILTERS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _filterSection('CATEGORY', ['Engine Parts', 'Brakes', 'Suspension', 'Exhaust', 'Lighting', 'Body Kits']),
            _filterSection('CONDITION', ['New', 'Used - Excellent', 'Used - Good']),
            _filterSection('SELLER RATING', ['4.5+', '4.0+', '3.5+']),
            const Text('PRICE RANGE', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text('0 – 5,000 AXC', style: TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
            Slider(value: 0.5, onChanged: (_) {}, activeColor: AppTheme.goldPrimary, inactiveColor: AppTheme.borderColor),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...options.map((o) => CheckboxListTile(
          value: false, onChanged: (_) {},
          title: Text(o, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          activeColor: AppTheme.goldPrimary,
          contentPadding: EdgeInsets.zero,
          dense: true,
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}