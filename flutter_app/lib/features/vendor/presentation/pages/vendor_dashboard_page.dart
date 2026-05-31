import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class VendorDashboardPage extends ConsumerStatefulWidget {
  const VendorDashboardPage({super.key});
  @override
  ConsumerState<VendorDashboardPage> createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends ConsumerState<VendorDashboardPage> {
  String _section = 'overview';

  final _navItems = [
    ('overview',   '📊', 'Dashboard'),
    ('products',   '📦', 'Products'),
    ('add',        '➕', 'Add Listing'),
    ('orders',     '🛒', 'Orders'),
    ('escrow',     '🛡️', 'Escrow'),
    ('payouts',    '💸', 'Payouts'),
    ('offers',     '💬', 'Offers'),
    ('bids',       '🔨', 'Bid Manager'),
    ('analytics',  '📈', 'Analytics'),
    ('messages',   '✉️', 'Messages'),
    ('shop',       '🏪', 'Shop Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VENDOR PANEL')),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 220,
            child: Container(
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppTheme.borderColor))),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor info
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('JDM Direct', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.colorGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.colorGreen.withOpacity(0.3))),
                          child: const Text('✓ Verified', style: TextStyle(fontSize: 9, color: AppTheme.colorGreen, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      const Text('🪙 12,400 AXC', style: TextStyle(fontSize: 12, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  ..._navItems.map((item) => _NavItem(
                    icon: item.$2, label: item.$3,
                    selected: _section == item.$1,
                    onTap: () => setState(() => _section = item.$1),
                  )),
                ],
              ),
            ),
          ),
          // Main content
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
      case 'overview': return const _VendorOverview();
      case 'add':      return const _AddListingForm();
      default:
        final item = _navItems.firstWhere((i) => i.$1 == _section);
        return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            Text(item.$2, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(item.$3.toUpperCase(), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
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
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppTheme.goldPrimary : AppTheme.textMuted)),
      ]),
    ),
  );
}

class _VendorOverview extends StatelessWidget {
  const _VendorOverview();

  static const _stats = [
    ('142K AXC', 'Total Sales',      AppTheme.goldPrimary,  '💰'),
    ('8,400 AXC','In Escrow',        AppTheme.colorPurple,  '🛡️'),
    ('48',       'Active Listings',  AppTheme.colorBlue,    '📦'),
    ('7',        'Pending Orders',   AppTheme.colorGreen,   '🚀'),
    ('4.9 ⭐',   'Avg Rating',       AppTheme.goldPrimary,  '🌟'),
    ('12',       'Open Offers',      AppTheme.colorBlue,    '💬'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('VENDOR DASHBOARD', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 3, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2,
        children: _stats.map((s) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(children: [
            Text(s.$4, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.$1, style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700, color: s.$3)),
              Text(s.$2, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
          ]),
        )).toList(),
      ),
    ],
  );
}

class _AddListingForm extends StatefulWidget {
  const _AddListingForm();
  @override
  State<_AddListingForm> createState() => _AddListingFormState();
}

class _AddListingFormState extends State<_AddListingForm> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _brandCtrl   = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _skuCtrl     = TextEditingController();
  final _qtyCtrl     = TextEditingController();
  final _descCtrl    = TextEditingController();
  bool _isNegotiable = false;
  bool _isAuction    = false;
  String _category   = 'Engine Parts';
  String _condition  = 'new';

  @override
  void dispose() {
    _titleCtrl.dispose(); _brandCtrl.dispose(); _priceCtrl.dispose();
    _skuCtrl.dispose();   _qtyCtrl.dispose();   _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ADD NEW LISTING', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
            child: Column(children: [
              _row([
                _field('Product Title', _titleCtrl, required: true),
                _field('Brand', _brandCtrl),
              ]),
              const SizedBox(height: 16),
              _row([
                _field('SKU', _skuCtrl),
                _field('Price (AXC)', _priceCtrl, keyboard: TextInputType.number, required: true),
                _field('Quantity', _qtyCtrl, keyboard: TextInputType.number),
              ]),
              const SizedBox(height: 16),
              _row([
                _dropdown('Category', _category, ['Engine Parts','Brakes','Suspension','Exhaust','Lighting','Body Kits','Interior','Electronics'], (v) => setState(() => _category = v!)),
                _dropdown('Condition', _condition, ['new','used_excellent','used_good','used_fair','refurbished'], (v) => setState(() => _condition = v!)),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _toggle('Negotiable', _isNegotiable, (v) => setState(() => _isNegotiable = v)),
                const SizedBox(width: 24),
                _toggle('Auction / Bidding', _isAuction, (v) => setState(() => _isAuction = v)),
              ]),
              const SizedBox(height: 16),
              // Image upload zone
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('📸', style: TextStyle(fontSize: 28)),
                  SizedBox(height: 6),
                  Text('Drag & drop images or tap to upload', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text('JPG, PNG, WebP · Max 10MB · Up to 8 images', style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing submitted for approval!')));
                    }
                  },
                  child: const Text('Publish Listing'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
    children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
  );

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, bool required = false}) =>
    TextFormField(
      controller: ctrl, keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: required ? (v) => v == null || v.isEmpty ? '$label is required' : null : null,
    );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) =>
    DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: AppTheme.bgCard,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Row(children: [
    Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.goldPrimary),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 13)),
  ]);
}
