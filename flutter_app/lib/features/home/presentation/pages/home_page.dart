import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/navbar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchCtrl = TextEditingController();
  final String _currentPage = 'home';
  final double _walletBalance = 2450.0;
  final int _notifications = 3;

  static const categories = [
    ('Engine Parts', '⚙️', '12,400'),
    ('Brakes', '🛑', '8,900'),
    ('Suspension', '🔩', '6,700'),
    ('Exhaust', '💨', '5,200'),
    ('Lighting', '💡', '9,800'),
    ('Body Kits', '🏎️', '4,300'),
    ('Interior', '🪑', '7,600'),
    ('Electronics', '📟', '11,200'),
  ];

  static const stats = [
    ('284K+', 'Active Listings', '📦'),
    ('12K+', 'Verified Vendors', '✅'),
    ('890K+', 'Happy Buyers', '🌟'),
    ('\$', '42M+ Coins Transacted', '🪙'),
  ];

  static const products = [
    ['Brembo GT 6-Piston', 'Brembo', 'Brakes', 2800.0, '🔴', 4.9, 234, 'ProBrake Co.'],
    ['HKS GT2 Supercharger', 'HKS', 'Engine Parts', 4200.0, '🟡', 4.8, 156, 'JDM Direct'],
    ['BC Racing Coilover', 'BC Racing', 'Suspension', 1200.0, '🔵', 4.7, 412, 'Track Ready'],
    ['Akrapovič Exhaust Ti', 'Akrapovič', 'Exhaust', 3600.0, '⚫', 5.0, 89, 'EU Performance'],
  ];

  static const vendors = [
    ['JDM Direct', '🇯🇵', '4.9', '12,400'],
    ['EU Performance', '🇩🇪', '4.8', '8,700'],
    ['ProBrake Co.', '🇺🇸', '4.9', '6,200'],
    ['Track Ready', '🇬🇧', '4.7', '9,100'],
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // Navbar
          Navbar(
            currentPage: _currentPage,
            walletBalance: _walletBalance,
            notifications: _notifications,
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(width),

                  // Stats Section
                  _buildStatsSection(width),

                  // Categories Section
                  _buildCategoriesSection(width),

                  // Trending Parts
                  _buildTrendingParts(width),

                  // Live Auctions
                  _buildLiveAuctions(width),

                  // Escrow Banner
                  _buildEscrowBanner(width),

                  // Top Verified Vendors
                  _buildTopVendors(width),

                  // Coin Banner
                  _buildCoinBanner(width),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: width > 768 ? 60 : 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.bgDark,
            AppTheme.bgCard.withOpacity(0.5),
            AppTheme.bgDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tag('🏆 #1 Auto Parts Marketplace', AppTheme.goldPrimary),
              const SizedBox(width: 8),
              _tag('✓ Escrow Protected', AppTheme.colorGreen),
            ],
          ),
          const SizedBox(height: 20),

          // Title with shimmer effect
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.goldPrimary, AppTheme.goldLight, Colors.white, AppTheme.goldLight, AppTheme.goldPrimary],
            ).createShader(bounds),
            child: Text(
              "THE WORLD'S\nPREMIUM AUTO\nPARTS EXCHANGE",
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.w900,
                fontSize: width > 768 ? 60 : 36,
                height: 1.1,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          SizedBox(
            width: width > 768 ? 500 : double.infinity,
            child: const Text(
              'Buy, sell, bid & negotiate on 284K+ verified auto parts. Every transaction escrow-protected with AUTOX Coins.',
              style: TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.7),
            ),
          ),
          const SizedBox(height: 32),

          // Search Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                // Search input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search parts, brands...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GradientButton(label: 'Search 🔍', onPressed: () => context.go('/marketplace')),
                  ],
                ),
                const SizedBox(height: 12),
                // Vehicle filters
                Wrap(
                  spacing: 10,
                  children: [
                    _filterSelect('Make', ['BMW', 'Toyota', 'Honda', 'Ford', 'Porsche']),
                    _filterSelect('Model', ['M3', 'Supra', 'Civic', 'Mustang', '911']),
                    _filterSelect('Year', ['2024', '2023', '2022', '2021', '2020']),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Trust Badges
          Wrap(
            spacing: 20,
            children: [
              _trustBadge('🛡️', 'Escrow Protected'),
              _trustBadge('⚡', 'Instant Payout'),
              _trustBadge('🌍', 'Ship Worldwide'),
              _trustBadge('💯', 'Verified Parts'),
            ],
          ),

          // Right decoration (desktop only)
          if (width > 768) ...[
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _liveStat('Live Auctions', '1,247', AppTheme.colorRed),
                const SizedBox(width: 12),
                _liveStat('Active Listings', '284K+', AppTheme.goldPrimary),
                const SizedBox(width: 12),
                _liveStat('Verified Vendors', '12K+', AppTheme.colorGreen),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _filterSelect(String hint, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: null,
          hint: Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          dropdownColor: AppTheme.bgCard,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _trustBadge(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _liveStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double width) {
    return Padding(
      padding: EdgeInsets.only(top: width > 768 ? 48 : 32, left: 24, right: 24),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: stats.length,
            itemBuilder: (ctx, i) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.bgCard.withOpacity(0.9),
                      const Color(0xFF141E32).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(stats[i].$3, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      stats[i].$1 == '42M+ Coins Transacted' ? '\$42M+' : stats[i].$1,
                      style: GoogleFonts.orbitron(
                        fontSize: stats[i].$1.length > 5 ? 18 : 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(stats[i].$2, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHOP BY CATEGORY',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/marketplace'),
                child: const Text('View All →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              return GestureDetector(
                onTap: () => context.go('/marketplace'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(categories[i].$2, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        categories[i].$1,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${categories[i].$3} listings',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildTrendingParts(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRENDING PARTS',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/marketplace'),
                child: const Text('Browse All →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              return _productCard(products[i]);
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _productCard(List<dynamic> product) {
    return GestureDetector(
      onTap: () => context.go('/product/${product[0].toLowerCase().replaceAll(' ', '-')}'),
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
              // Image placeholder
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    product[4],
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product[1].toUpperCase()} · ${product[2].toUpperCase()}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product[0],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < product[5].floor() ? Icons.star : Icons.star_border,
                          size: 12,
                          color: AppTheme.goldLight,
                        )),
                        const SizedBox(width: 4),
                        Text('${product[5]} (${product[6]})', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product[3].toStringAsFixed(0)} AXC',
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                              Text(
                                '≈ \$${product[3].toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.go('/product/${product[0].toLowerCase().replaceAll(' ', '-')}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Buy'),
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
                            product[7],
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

  Widget _buildLiveAuctions(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔨 LIVE AUCTIONS',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/auctions'),
                child: const Text('All Auctions →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              return _auctionCard(products[i]);
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _auctionCard(List<dynamic> product) {
    return GestureDetector(
      onTap: () => context.go('/product/${product[0].toLowerCase().replaceAll(' ', '-')}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      product[4],
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                // Auction badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.colorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.colorRed.withOpacity(0.3)),
                    ),
                    child: const Text('🔨 Auction', style: TextStyle(fontSize: 10, color: AppTheme.colorRed, fontWeight: FontWeight.w600)),
                  ),
                ),
                // Timer
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.colorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⏱ 2h 14m', style: TextStyle(fontSize: 10, color: AppTheme.colorRed)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product[0],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text('23 bids', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 10),
                  Text(
                    '${product[3].toStringAsFixed(0)} AXC',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/product/${product[0].toLowerCase().replaceAll(' ', '-')}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Bid Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowBanner(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.colorPurple.withOpacity(0.08),
              AppTheme.colorBlue.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.colorPurple.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESCROW PROTECTED TRANSACTIONS',
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payments are securely held in marketplace escrow until vendors successfully deliver the ordered products. Buyers may request refunds if products are not delivered as described.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.7),
                  ),
                ],
              ),
            ),
            if (width > 768)
              Column(
                children: [
                  _escrowStep('1', 'Buyer pays with coins'),
                  const SizedBox(height: 8),
                  _escrowStep('2', 'Coins held in escrow'),
                  const SizedBox(height: 8),
                  _escrowStep('3', 'Item shipped & received'),
                  const SizedBox(height: 8),
                  _escrowStep('4', 'Coins released to vendor'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _escrowStep(String num, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.colorPurple, AppTheme.colorBlue]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildTopVendors(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP VERIFIED VENDORS',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('All Vendors →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: vendors.length,
            itemBuilder: (ctx, i) {
              return GestureDetector(
                onTap: () => context.go('/vendor/${vendors[i][0].toLowerCase().replaceAll(' ', '-')}'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldDark]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                vendors[i][1],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendors[i][0],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.colorGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.colorGreen.withOpacity(0.3)),
                                  ),
                                  child: const Text('✓ Verified', style: TextStyle(fontSize: 10, color: AppTheme.colorGreen)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 12)),
                              Text(vendors[i][2], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('${vendors[i][3]} sales', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildCoinBanner(double width) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A0F00), Color(0xFF2D1A00)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 52)),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTOX COIN WALLET',
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Top up your wallet using bank transfer. Use AUTOX Coins to purchase parts instantly — no checkout friction, maximum security.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.7),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _tag('Bank Transfer', AppTheme.goldPrimary),
                      _tag('Wire Transfer', AppTheme.goldPrimary),
                      _tag('ACH', AppTheme.goldPrimary),
                    ],
                  ),
                ],
              ),
            ),
            if (width > 768)
              GradientButton(label: 'Top Up Coins →', onPressed: () => context.push('/wallet')),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF060A12),
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Footer grid
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Wrap(
              spacing: 32,
              runSpacing: 32,
              children: [
                // Brand section
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldDark]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'AX',
                                style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldLight]).createShader(bounds),
                            child: Text('AUTOX', style: GoogleFonts.orbitron(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "The world's premium auto parts marketplace. Secure, escrow-protected transactions.",
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.7),
                      ),
                    ],
                  ),
                ),
                // Marketplace section
                _footerColumn('Marketplace', [
                  ('Browse Parts', '/marketplace'),
                  ('Live Auctions', '/auctions'),
                  ('Make Offers', '/marketplace?type=negotiable'),
                  ('Featured Listings', '/marketplace?badge=featured'),
                  ('Vendor Stores', '/vendors'),
                ]),
                // Account section
                _footerColumn('Account', [
                  ('Dashboard', '/dashboard'),
                  ('Wallet', '/wallet'),
                  ('Orders', '/orders'),
                  ('Messages', '/chat'),
                  ('Settings', '/settings'),
                ]),
                // Legal section
                _footerColumn('Legal', [
                  ('Terms of Service', '/terms'),
                  ('Privacy Policy', '/privacy'),
                  ('Escrow Policy', '/escrow-policy'),
                  ('Refund Policy', '/refund-policy'),
                  ('Cookie Policy', '/cookies'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bottom bar
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '© 2024 AUTOX Marketplace. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textDim),
                  ),
                  Row(
                    children: ['PayPal', 'Visa', 'MC', 'Amex'].map((m) {
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                        ),
                        child: Text(m, style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<(String, String)> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 14),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () => context.push(link.$2),
            child: MouseRegion(
              onEnter: (_) {},
              onExit: (_) {},
              child: Text(
                link.$1,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ),
        )),
      ],
    );
  }
}
