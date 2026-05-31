import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  String? _selectedType;
  String  _sortBy  = 'newest';
  final int     _page    = 1;
  Map<String, dynamic> get _filters => {
    'productType': _selectedType,
    'sortBy': _sortBy,
    'page': _page,
  };

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(marketplaceProductsProvider(_filters));

    return Scaffold(
      appBar: AppBar(title: const Text('MARKETPLACE')),
      body: Row(
        children: [
          // Sidebar filters (desktop only)
          if (MediaQuery.of(context).size.width > 768)
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
                          DropdownMenuItem(value: 'newest',     child: Text('Newest')),
                          DropdownMenuItem(value: 'price_low',  child: Text('Price: Low-High')),
                          DropdownMenuItem(value: 'price_high', child: Text('Price: High-Low')),
                          DropdownMenuItem(value: 'rating',     child: Text('Top Rated')),
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
                              // In production, parse from JSON; here we show placeholder
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(products[i]['title'] ?? 'Product'),
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
