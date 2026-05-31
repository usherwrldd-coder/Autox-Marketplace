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
  String _currentPage = 'home';
  double _walletBalance = 2450.0;
  int _notifications = 3;

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

                  // Escrow Banner
                  const _EscrowBanner(),

                  // Coin Banner
                  _buildCoinBanner(width),

                  // Footer Spacer
                  const SizedBox(height: 40),
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

          // Title
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
            child: Text(
              'Buy, sell, bid & negotiate on 284K+ verified auto parts. Every transaction escrow-protected with AUTOX Coins.',
              style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.7),
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
                        decoration: InputDecoration(
                          hintText: 'Search parts, brands...',
                          prefixIcon: const Icon(Icons.search),
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
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
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
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
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
}

class _EscrowBanner extends StatelessWidget {
  const _EscrowBanner();

  @override
  Widget build(BuildContext context) {
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
            if (MediaQuery.of(context).size.width > 768)
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.colorPurple, AppTheme.colorBlue]),
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
}