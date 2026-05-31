import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverToBoxAdapter(child: _HeroSection()),
          // Stats
          const SliverToBoxAdapter(child: _StatsSection()),
          // Categories
          const SliverToBoxAdapter(child: _CategoriesSection()),
          // Escrow Banner
          const SliverToBoxAdapter(child: _EscrowBanner()),
          // Coin Banner
          const SliverToBoxAdapter(child: _CoinBanner()),
          // Footer spacer
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final _searchCtrl = TextEditingController();

  _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgDark, AppTheme.bgCard.withOpacity(0.5), AppTheme.bgDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            _Tag('🏆 #1 Auto Parts Marketplace', AppTheme.goldPrimary),
            SizedBox(width: 8),
            _Tag('✓ Escrow Protected', AppTheme.colorGreen),
          ]),
          const SizedBox(height: 20),
          Text(
            'THE WORLD\'S\nPREMIUM AUTO\nPARTS EXCHANGE',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.w900,
              fontSize: 48, height: 1.1, color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Buy, sell, bid & negotiate on 284K+ verified auto parts.\nEvery transaction escrow-protected with AUTOX Coins.',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.7),
          ),
          const SizedBox(height: 32),
          // Search box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search parts, brands, vehicles...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none, enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none, filled: false,
                  ),
                ),
              ),
              GradientButton(label: 'Search', onPressed: () => context.go('/marketplace')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class _StatsSection extends StatelessWidget {
  static const stats = [
    ('284K+', 'Active Listings',   '📦'),
    ('12K+',  'Verified Vendors',  '✅'),
    ('890K+', 'Happy Buyers',      '🌟'),
    ('\$42M+','Coins Transacted',  '🪙'),
  ];

  const _StatsSection();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: GridView.count(
      crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2,
      children: stats.map((s) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.$3, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(s.$1, style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
          Text(s.$2, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
      )).toList(),
    ),
  );
}

class _CategoriesSection extends StatelessWidget {
  static const categories = [
    ('Engine Parts', '⚙️', '12,400'), ('Brakes', '🛑', '8,900'),
    ('Suspension', '🔩', '6,700'),    ('Exhaust', '💨', '5,200'),
    ('Lighting', '💡', '9,800'),      ('Body Kits', '🏎️', '4,300'),
    ('Interior', '🪑', '7,600'),       ('Electronics', '📟', '11,200'),
  ];

  const _CategoriesSection();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SHOP BY CATEGORY', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)), // Note: Orbitron via Google Fonts needs MaterialApp.fontFamily set
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: categories.map((c) => GestureDetector(
            onTap: () => context.push('/marketplace'),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.$2, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(c.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                Text('${c.$3} listings', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class _EscrowBanner extends StatelessWidget {
  const _EscrowBanner();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.colorPurple.withOpacity(0.08), AppTheme.colorBlue.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorPurple.withOpacity(0.2)),
      ),
      child: const Row(children: [
        Text('🛡️', style: TextStyle(fontSize: 48)),
        SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ESCROW PROTECTED TRANSACTIONS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, color: AppTheme.colorPurple, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Payments are securely held in marketplace escrow until vendors successfully deliver the ordered products. Buyers may request refunds if products are not delivered as described.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.6),
          ),
        ])),
      ]),
    ),
  );
}

class _CoinBanner extends StatelessWidget {
  const _CoinBanner();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0F00), Color(0xFF2D1A00)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Text('🪙', style: TextStyle(fontSize: 48)),
        const SizedBox(width: 20),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AUTOX COIN WALLET', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, color: AppTheme.goldPrimary, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Deposit funds via bank transfer. Use AUTOX Coins to buy parts instantly.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.6)),
        ])),
        GradientButton(label: 'Top Up →', onPressed: () => context.push('/wallet')),
      ]),
    ),
  );
}
