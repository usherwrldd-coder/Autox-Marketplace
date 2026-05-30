import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import 'deposit_review_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _section = 'overview';

  final _navItems = [
    ('overview',   '📊', 'Dashboard'),
    ('users',      '👥', 'Users'),
    ('vendors',    '🏪', 'Vendors'),
    ('listings',   '📦', 'Listings'),
    ('escrow',     '🛡️', 'Escrow'),
    ('refunds',    '↩️', 'Refunds'),
    ('disputes',   '⚖️', 'Disputes'),
    ('coins',      '🪙', 'Coin Controls'),
    ('kyc',        '🪪', 'KYC'),
    ('analytics',  '📈', 'Analytics'),
    ('revenue',    '💰', 'Revenue'),
    ('fraud',      '🚨', 'Fraud Monitor'),
    ('deposits',   '🏦', 'Deposits'),
    ('fees',       '💲', 'Fee Settings'),
    ('cms',        '📝', 'CMS Pages'),
    ('settings',   '⚙️', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Text('ADMIN PANEL'),
          SizedBox(width: 10),
          _AdminBadge(),
        ]),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: Container(
              color: const Color(0xFF060A12),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Text('ADMINISTRATION', style: TextStyle(fontSize: 9, color: AppTheme.goldPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  Expanded(
                    child: ListView(
                      children: _navItems.map((item) => _AdminNavItem(
                        icon: item.$2, label: item.$3,
                        selected: _section == item.$1,
                        onTap: () => setState(() => _section = item.$1),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      case 'overview': return const _AdminOverview();
      case 'coins':    return const _CoinControlsSection();
      case 'deposits': return const DepositReviewPage();
      case 'fees':     return const _FeeSettingsSection();
      default:
        final item = _navItems.firstWhere((i) => i.$1 == _section);
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              Text(item.$2, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(item.$3.toUpperCase(), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Full admin module active in production build.', style: TextStyle(color: AppTheme.textMuted)),
            ]),
          ),
        );
    }
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.colorRed.withOpacity(0.15), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.colorRed.withOpacity(0.4)),
    ),
    child: const Text('SUPER ADMIN', style: TextStyle(fontSize: 10, color: AppTheme.colorRed, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

class _AdminNavItem extends StatelessWidget {
  final String icon, label;
  final bool selected;
  final VoidCallback onTap;
  const _AdminNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppTheme.goldPrimary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppTheme.goldPrimary.withOpacity(0.25) : Colors.transparent),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 12, color: selected ? AppTheme.goldPrimary : AppTheme.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ]),
    ),
  );
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  static const _stats = [
    ('\$1.24M', 'Total Revenue',    AppTheme.goldPrimary,  '💰'),
    ('\$42K',   'Platform Fees',    AppTheme.colorGreen,   '💲'),
    ('\$284K',  'In Escrow',        AppTheme.colorPurple,  '🛡️'),
    ('89,240',  'Active Users',     AppTheme.colorBlue,    '👥'),
    ('124',     'Pending KYC',      AppTheme.goldPrimary,  '🪪'),
    ('18',      'Open Disputes',    AppTheme.colorRed,     '⚖️'),
    ('1,247',   'Live Auctions',    AppTheme.colorBlue,    '🔨'),
    ('284K',    'Active Listings',  AppTheme.colorGreen,   '📦'),
  ];

  static const _activities = [
    ('New Vendor Registration', 'speedparts_uk',   '2m ago',  '🏪', AppTheme.colorBlue),
    ('Dispute Opened',          'buyer_92841',     '8m ago',  '⚖️', AppTheme.colorRed),
    ('KYC Submitted',           'jdm_shop_osaka',  '15m ago', '🪪', AppTheme.goldPrimary),
    ('Large Escrow Release',    'eu_perf_gmbh',    '22m ago', '🛡️', AppTheme.colorPurple),
    ('Fraud Alert Triggered',   'unknown_device',  '1h ago',  '🚨', AppTheme.colorRed),
    ('Refund Request',          'buyer_44120',     '1h ago',  '↩️', AppTheme.colorBlue),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('ADMIN DASHBOARD', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.8,
        children: _stats.map((s) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.$4, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(s.$1, style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, fontWeight: FontWeight.w700, color: s.$3)),
            Text(s.$2, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
        )).toList(),
      ),
      const SizedBox(height: 28),
      const Text('RECENT ACTIVITY', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      ..._activities.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: a.$5.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(a.$4, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('@${a.$2}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          Text(a.$3, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero, textStyle: const TextStyle(fontSize: 11)),
            child: const Text('Review'),
          ),
        ]),
      )).toList(),
    ],
  );
}

class _CoinControlsSection extends StatelessWidget {
  const _CoinControlsSection();

  static const _fields = [
    ('AXC to USD Rate',       '1.00',  'USD'),
    ('Platform Fee',          '3.5',   '%'),
    ('Withdrawal Fee',        '1.5',   '%'),
    ('Min Top-Up',            '10',    'AXC'),
    ('Max Top-Up Daily',      '50000', 'AXC'),
    ('Withdrawal Cooldown',   '24',    'hours'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('COIN CONTROLS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 3,
        children: _fields.map((f) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(f.$1, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              TextFormField(initialValue: f.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6))),
            ])),
            const SizedBox(width: 10),
            Text(f.$3, style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
          ]),
        )).toList(),
      ),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () {}, child: const Text('Save Coin Settings')),
    ],
  );
}

class _FeeSettingsSection extends StatelessWidget {
  const _FeeSettingsSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('FEE SETTINGS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
        child: Column(children: [
          ...[
            ('Buyer Transaction Fee', '0', '%', 'Charged to buyers on purchase'),
            ('Vendor Commission',     '3.5', '%', 'Charged from vendor on escrow release'),
            ('Withdrawal Fee',        '1.5', '%', 'Charged on vendor payout'),
            ('Featured Listing Fee',  '50',  'AXC', 'One-time fee per featured slot'),
            ('Auction Listing Fee',   '0',   'AXC', 'Currently free'),
          ].map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(f.$4, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ])),
              SizedBox(width: 100, child: TextFormField(initialValue: f.$2, style: const TextStyle(fontSize: 14), decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)))),
              const SizedBox(width: 8),
              Text(f.$3, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
            ]),
          )).toList(),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: const Text('Save Fee Settings'))),
        ]),
      ),
    ],
  );
}
