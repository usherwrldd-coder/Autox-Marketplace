import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/auction/presentation/pages/auctions_page.dart';
import '../../features/product/presentation/pages/product_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/deposit_history_page.dart';
import '../../features/buyer/presentation/pages/buyer_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/deposit_review_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart' show ChatDetailPage;
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
      initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final protectedRoutes = ['/dashboard', '/wallet', '/chat', '/vendor-panel', '/admin', '/orders', '/notifications'];
      final isProtected = protectedRoutes.any((r) => state.matchedLocation.startsWith(r));
      if (isProtected && user == null) return '/login?redirect=${state.matchedLocation}';
      
      // Admin routes should only be accessible from admin.com domain
      if (state.matchedLocation.startsWith('/admin')) {
        final uri = Uri.base;
        final host = uri.host.toLowerCase();
        // Check if domain is admin.com or ends with .admin.com
        final isAdminDomain = host == 'admin.com' || host.endsWith('.admin.com') || host.contains('admin.com');
        if (!isAdminDomain) {
          return '/'; // Redirect to home if not on admin.com domain
        }
      }
      
      return null;
    },
    routes: [
      // Public pages
      GoRoute(path: '/',              name: 'home',        builder: (c, s) => const HomePage()),
      GoRoute(path: '/marketplace',   name: 'marketplace', builder: (c, s) => const MarketplacePage()),
      GoRoute(path: '/auctions',      name: 'auctions',    builder: (c, s) => const AuctionsPage()),
      GoRoute(path: '/product/:slug', name: 'product',     builder: (c, s) => ProductPage(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/search',        name: 'search',      builder: (c, s) => const SearchPage()),
      
      // Auth pages
      GoRoute(path: '/login',         name: 'login',       builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register',      name: 'register',    builder: (c, s) => const RegisterPage()),
      GoRoute(path: '/forgot-password', name: 'forgot-password', builder: (c, s) => const Scaffold(
        body: Center(child: Text('Forgot Password - Coming Soon')),
      )),
      
      // User pages (protected)
      GoRoute(path: '/wallet',        name: 'wallet',      builder: (c, s) => const WalletPage()),
      GoRoute(path: '/deposit-history', name: 'deposit-history', builder: (c, s) => const DepositHistoryPage()),
      GoRoute(path: '/dashboard',     name: 'dashboard',   builder: (c, s) => const BuyerDashboardPage()),
      GoRoute(path: '/orders',        name: 'orders',      builder: (c, s) => const OrdersPage()),
      GoRoute(path: '/chat',          name: 'chat',        builder: (c, s) => const Scaffold(body: Center(child: Text('Messages - Select a conversation')))),
      GoRoute(path: '/chat/:id',      name: 'chat-detail', builder: (c, s) => ChatDetailPage(id: s.pathParameters['id']!)),
      GoRoute(path: '/notifications', name: 'notifications', builder: (c, s) => const NotificationsPage()),
      
      // Vendor pages
      GoRoute(path: '/vendor/:slug',  name: 'vendor-shop', builder: (c, s) => Scaffold(
        body: Center(child: Text('Vendor: ${s.pathParameters["slug"]}')),
      )),
      ShellRoute(
        builder: (c, s, child) => child,
        routes: [
          GoRoute(path: '/vendor-panel',           name: 'vendor-panel',    builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Dashboard - Coming Soon')))),
          GoRoute(path: '/vendor-panel/products',  name: 'vendor-products', builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Products - Coming Soon')))),
          GoRoute(path: '/vendor-panel/add',       name: 'vendor-add',      builder: (c, s) => const Scaffold(body: Center(child: Text('Add Product - Coming Soon')))),
          GoRoute(path: '/vendor-panel/orders',    name: 'vendor-orders',   builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Orders - Coming Soon')))),
          GoRoute(path: '/vendor-panel/escrow',    name: 'vendor-escrow',   builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Escrow - Coming Soon')))),
          GoRoute(path: '/vendor-panel/analytics', name: 'vendor-analytics',builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Analytics - Coming Soon')))),
          GoRoute(path: '/vendor-panel/messages',  name: 'vendor-messages', builder: (c, s) => const Scaffold(body: Center(child: Text('Vendor Messages - Coming Soon')))),
        ],
      ),
      
      // Admin pages (protected)
      ShellRoute(
        builder: (c, s, child) => child,
        routes: [
          GoRoute(path: '/admin',              name: 'admin',           builder: (c, s) => const AdminDashboardPage()),
          GoRoute(path: '/admin/deposits',     name: 'admin-deposits',  builder: (c, s) => const DepositReviewPage()),
          GoRoute(path: '/admin/users',        name: 'admin-users',     builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Users - Coming Soon')))),
          GoRoute(path: '/admin/listings',     name: 'admin-listings',  builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Listings - Coming Soon')))),
          GoRoute(path: '/admin/escrow',       name: 'admin-escrow',    builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Escrow - Coming Soon')))),
          GoRoute(path: '/admin/refunds',      name: 'admin-refunds',   builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Refunds - Coming Soon')))),
          GoRoute(path: '/admin/disputes',     name: 'admin-disputes',  builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Disputes - Coming Soon')))),
          GoRoute(path: '/admin/analytics',    name: 'admin-analytics', builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Analytics - Coming Soon')))),
          GoRoute(path: '/admin/coins',        name: 'admin-coins',     builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Coins - Coming Soon')))),
          GoRoute(path: '/admin/settings',     name: 'admin-settings',  builder: (c, s) => const Scaffold(body: Center(child: Text('Admin Settings - Coming Soon')))),
        ],
      ),
      
      // Info pages
      GoRoute(path: '/blog',          name: 'blog',        builder: (c, s) => const Scaffold(body: Center(child: Text('Blog - Coming Soon')))),
      GoRoute(path: '/blog/:slug',    name: 'blog-post',   builder: (c, s) => const Scaffold(body: Center(child: Text('Blog Post - Coming Soon')))),
      GoRoute(path: '/faq',           name: 'faq',         builder: (c, s) => const Scaffold(body: Center(child: Text('FAQ - Coming Soon')))),
      GoRoute(path: '/about',         name: 'about',       builder: (c, s) => const Scaffold(body: Center(child: Text('About - Coming Soon')))),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('404 — Page Not Found', style: TextStyle(fontSize: 24)),
          TextButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
        ],
      )),
    ),
  );
});