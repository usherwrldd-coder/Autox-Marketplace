import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

class BuyerDashboardPage extends ConsumerStatefulWidget {
  const BuyerDashboardPage({super.key});
  @override
  ConsumerState<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends ConsumerState<BuyerDashboardPage> {
  String _section = 'overview';

  final _navItems = [
    ('overview',     '📊', 'Overview'),
    ('orders',       '📦', 'Orders'),
    ('escrow',       '🛡️', 'Escrow'),
    ('bids',         '🔨', 'My Bids'),
    ('offers',       '💬', 'Offers'),
    ('wishlist',     '❤️', 'Wishlist'),
    ('messages',     '✉️', 'Messages'),
    ('notifications','🔔', 'Notifications'),
    ('addresses',    '📍', 'Addresses'),
    ('settings',     '⚙️', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final client = ref.read(supabaseClientProvider);
    final user   = client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('MY DASHBOARD')),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 220,
            child: Container(
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppTheme.borderColor))),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.goldPrimary,
                        child: Text((user?.email ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      Text(user?.email?.split('@').first ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Buyer Account', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ]),
                  ),
                  // Nav items
                  ..._navItems.map((item) => _NavItem(
                    icon: item.$2, label: item.$3,
                    selected: _section == item.$1,
                    onTap: () => setState(() => _section = item.$1),
                  )),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 'overview': return const _OverviewSection();
      case 'orders':   return const Center(child: Text('Navigate to Orders page for full order management.'));
      default: return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_navItems.firstWhere((i) => i.$1 == _section).$2, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(_navItems.firstWhere((i) => i.$1 == _section).$3.toUpperCase(),
            style: const TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Full module active in production build.', style: TextStyle(color: AppTheme.textMuted)),
        ]),
      );
    }
  }
}

class _NavItem extends StatelessWidget {
  final String icon, label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.goldPrimary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppTheme.goldPrimary.withOpacity(0.3) : Colors.transparent),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppTheme.goldPrimary : AppTheme.textMuted)),
      ]),
    ),
  );
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  static const _stats = [
    ('24', 'Total Orders',   '📦'),
    ('2,800 AXC', 'In Escrow', '🛡️'),
    ('3',  'Active Bids',    '🔨'),
    ('12', 'Wishlist Items', '❤️'),
  ];

  static const _colors = [
    AppTheme.colorBlue,
    AppTheme.colorPurple,
    AppTheme.colorRed,
    AppTheme.goldPrimary,
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('DASHBOARD OVERVIEW', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.6,
        children: List.generate(_stats.length, (i) {
          final s = _stats[i];
          final color = _colors[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.$3, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(s.$1, style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              Text(s.$2, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
          );
        }),
      ),
    ],
  );
}
