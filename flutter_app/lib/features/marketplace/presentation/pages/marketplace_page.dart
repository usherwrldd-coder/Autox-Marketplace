import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

final marketplaceProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  final svc = ref.watch(supabaseServiceProvider);
  return svc.fetchProducts(
    categoryId:  filters['categoryId'],
    minPrice:    filters['minPrice'],
    maxPrice:    filters['maxPrice'],
    condition:   filters['condition'],
    productType: filters['productType'],
    vehicleMake: filters['vehicleMake'],
    page:        filters['page'] ?? 1,
  );
});

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
  
  Map<String, dynamic> get _filters => {
    'productType': _selectedType,
    'sortBy': _sortBy,
    'page': _page,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(marketplaceProductsProvider(_filters));
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // Custom Header with AUTOX Logo and Coin Balance
          _buildHeader(),
          
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
                        child: productsAsync.when(
                          data: (products) => products.isEmpty
                              ? const Center(child: Text('No products found', style: TextStyle(color: AppTheme.textMuted)))
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 280, crossAxisSpacing: 16,
                                    mainAxisSpacing: 16, childAspectRatio: 0.7,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (ctx, i) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.build, size: 48, color: AppTheme.goldPrimary),
                                            const SizedBox(height: 8),
                                            Text(products[i]['title'] ?? 'Product', 
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                              maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const Spacer(),
                                            Text('AOC ${products[i]['price'] ?? '0.00'}',
                                              style: GoogleFonts.orbitron(
                                                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.colorRed))),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // AUTOX Logo
          Text('AUTOX',
            style: GoogleFonts.orbitron(
              fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.goldPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text('MARKETPLACE',
            style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          // Coin Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('2,450.00 AXC',
                  style: GoogleFonts.orbitron(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Notification Bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          // User Avatar
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.goldPrimary,
            child: Icon(Icons.person, color: Colors.black, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.goldPrimary,
        indicatorWeight: 2,
        labelColor: AppTheme.goldPrimary,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w600),
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
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _footerLink('About'),
              _footerLink('Help'),
              _footerLink('Terms'),
              _footerLink('Privacy'),
              _footerLink('Contact'),
            ],
          ),
          const SizedBox(height: 16),
          Text('© 2024 AUTOX Marketplace. All rights reserved.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return GestureDetector(
      onTap: () {},
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