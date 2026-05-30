class AppConstants {
  AppConstants._();

  static const String appName        = 'AUTOX Marketplace';
  static const String appSlogan      = 'The World\'s Premium Auto Parts Exchange';
  static const String coinSymbol     = 'AXC';
  static const String coinName       = 'AUTOX Coins';
  static const double coinToUsd      = 1.0;

  static const String supabaseUrl    = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey    = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String paypalClientId = String.fromEnvironment('PAYPAL_CLIENT_ID');

  // Pagination
  static const int defaultPageSize   = 24;
  static const int chatPageSize      = 50;
  static const int notifPageSize     = 20;

  // Limits
  static const int maxProductImages  = 8;
  static const int maxFileUploadMB   = 10;
  static const int minTopUpCoins     = 10;
  static const int maxTopUpDaily     = 50000;

  // Timeouts
  static const Duration apiTimeout     = Duration(seconds: 30);
  static const Duration cacheTimeout   = Duration(minutes: 5);

  // Escrow
  static const String escrowNotice =
    'Payments are securely held in marketplace escrow until vendors '
    'successfully deliver the ordered products. Buyers may request '
    'refunds if products are not delivered as described.';

  // Routes
  static const String routeHome      = '/';
  static const String routeMarket    = '/marketplace';
  static const String routeAuctions  = '/auctions';
  static const String routeWallet    = '/wallet';
  static const String routeDashboard = '/dashboard';
  static const String routeChat      = '/chat';
  static const String routeLogin     = '/login';
  static const String routeRegister  = '/register';
  static const String routeAdmin     = '/admin';
  static const String routeVendor    = '/vendor-panel';

  // Storage Buckets
  static const String bucketProducts = 'product-images';
  static const String bucketAvatars  = 'avatars';
  static const String bucketShop     = 'shop-assets';
  static const String bucketKyc      = 'kyc-documents';
  static const String bucketChat     = 'chat-images';
}
