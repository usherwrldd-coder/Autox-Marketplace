import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class Navbar extends StatefulWidget {
  final String currentPage;
  final double walletBalance;
  final int notifications;

  const Navbar({
    super.key,
    required this.currentPage,
    required this.walletBalance,
    required this.notifications,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool _hoveredAvatar = false;
  bool _isAdmin = false;
  bool _showUserMenu = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Check if user email is from admin.com domain
      final email = user.email ?? '';
      final isAdmin = email.endsWith('@admin.com');
      if (mounted) {
        setState(() => _isAdmin = isAdmin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Navbar
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withOpacity(0.95),
            border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.goldPrimary, AppTheme.goldDark],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'AX',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.goldPrimary, AppTheme.goldLight],
                        ).createShader(bounds),
                        child: Text(
                          'AUTOX',
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar (desktop only)
                if (!isMobile)
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search parts, brands, vehicles...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintStyle: TextStyle(color: AppTheme.textDim),
                        ),
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      ),
                    ),
                  ),

                // Nav Links (desktop only)
                if (!isMobile)
                  Row(
                    children: [
                      _navLink('home', 'Home'),
                      _navLink('marketplace', 'Marketplace'),
                      _navLink('auctions', 'Auctions'),
                    ],
                  ),

                const Spacer(),

                // Wallet Balance
                GestureDetector(
                  onTap: () => context.push('/wallet'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.walletBalance.toStringAsFixed(0)} AXC',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Notifications
                GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Stack(
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 22)),
                      if (widget.notifications > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppTheme.colorRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.notifications}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // User Avatar with Menu
                Builder(
                  builder: (ctx) => MouseRegion(
                    onEnter: (_) => setState(() => _hoveredAvatar = true),
                    onExit: (_) => setState(() => _hoveredAvatar = false),
                    child: GestureDetector(
                      onTap: () => _showUserMenu ? _hideUserMenu() : _showUserMenuDropdown(ctx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.goldPrimary, AppTheme.goldDark],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: _hoveredAvatar
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldPrimary.withOpacity(0.4),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: const Center(
                          child: Text(
                            'JD',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Menu Bar (Horizontal Scrollable)
        Container(
          height: 44,
          decoration: const BoxDecoration(
            color: AppTheme.bgCard,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _actionMenuItem('home', '🏠 Home', '/'),
                _actionMenuItem('marketplace', '🛒 Marketplace', '/marketplace'),
                _actionMenuItem('auctions', '🔨 Auctions', '/auctions'),
                _actionMenuItem('product', '📦 Product', '/product/1'),
                _actionMenuItem('wallet', '💰 Wallet', '/wallet'),
                _actionMenuItem('dashboard', '👤 Buyer Dashboard', '/dashboard'),
                _actionMenuItem('orders', '📋 Orders', '/orders'),
                _actionMenuItem('chat', '💬 Chat', '/chat'),
                _actionMenuItem('vendor-panel', '🏪 Vendor Panel', '/vendor-panel'),
                if (_isAdmin)
                  _actionMenuItem('admin', '⚙️ Admin', '/admin'),
                _actionMenuItem('notifications', '🔔 Notifications', '/notifications'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionMenuItem(String id, String label, String path) {
    final isActive = widget.currentPage == id;
    return GestureDetector(
      onTap: () => context.go(path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.goldPrimary.withOpacity(0.3) : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? AppTheme.goldPrimary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  void _showUserMenuDropdown(BuildContext context) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: box.localToGlobal(Offset.zero).dy + 64,
        right: MediaQuery.of(context).size.width - (box.localToGlobal(Offset.zero).dx + 36),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                _userMenuItem('👤 My Profile', () {
                  overlayEntry.remove();
                  context.go('/dashboard');
                }),
                _userMenuItem('💰 Wallet', () {
                  overlayEntry.remove();
                  context.go('/wallet');
                }),
                _userMenuItem('📋 My Orders', () {
                  overlayEntry.remove();
                  context.go('/orders');
                }),
                _userMenuItem('💬 Messages', () {
                  overlayEntry.remove();
                  context.go('/chat');
                }),
                _userMenuItem('🔔 Notifications', () {
                  overlayEntry.remove();
                  context.go('/notifications');
                }),
                if (_isAdmin)
                  _userMenuItem('⚙️ Admin Panel', () {
                    overlayEntry.remove();
                    context.go('/admin');
                  }),
                const Divider(height: 1, color: AppTheme.borderColor),
                _userMenuItem('🚪 Logout', () {
                  overlayEntry.remove();
                  Supabase.instance.client.auth.signOut();
                  context.go('/');
                }),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    setState(() => _showUserMenu = true);
  }

  void _hideUserMenu() {
    setState(() => _showUserMenu = false);
  }

  Widget _userMenuItem(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String page, String label) {
    final isActive = widget.currentPage == page;
    return GestureDetector(
      onTap: () => context.go(page == 'home' ? '/' : '/$page'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.goldPrimary.withOpacity(0.25) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppTheme.goldPrimary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}