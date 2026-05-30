import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

class SupabaseService {
  final SupabaseClient client;
  SupabaseService(this.client);

  // Products
  Future<List<Map<String, dynamic>>> fetchProducts({
    String? query, String? categoryId, int? minPrice, int? maxPrice,
    String? condition, String? productType, String? vehicleMake,
    String? vehicleModel, int? vehicleYear, int page = 1, int pageSize = 24,
  }) async {
    var rb = client.from('products')
        .select('*, vendor_profiles(shop_name, is_verified)')
        .eq('is_active', true)
        .eq('is_approved', true);

    if (categoryId != null) rb = rb.eq('category_id', categoryId);
    if (minPrice   != null) rb = rb.gte('price_coins', minPrice);
    if (maxPrice   != null) rb = rb.lte('price_coins', maxPrice);
    if (condition  != null) rb = rb.eq('condition', condition);
    if (productType!= null) rb = rb.eq('product_type', productType);
    if (vehicleMake!= null) rb = rb.filter('vehicle_make', 'ilike', '%$vehicleMake%');

    final data = await rb
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>?> fetchProductBySlug(String slug) async {
    final data = await client.from('products')
        .select('*, vendor_profiles(*), categories(name, slug)')
        .eq('slug', slug)
        .eq('is_active', true)
        .single();

    // Increment view count
    await client.from('products')
        .update({'view_count': data['view_count'] + 1})
        .eq('id', data['id']);

    return data;
  }

  // Wallet
  Future<Map<String, dynamic>?> fetchWallet(String userId) async {
    return await client.from('wallets').select().eq('user_id', userId).single();
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(String userId, {int limit = 50}) async {
    return await client.from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  // Orders
  Future<List<Map<String, dynamic>>> fetchBuyerOrders(String buyerId) async {
    return await client.from('orders')
        .select('*, products(title, images), vendor_profiles(shop_name)')
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchVendorOrders(String vendorId) async {
    return await client.from('orders')
        .select('*, products(title, images), profiles(full_name, username)')
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
  }

  // Messages
  Future<List<Map<String, dynamic>>> fetchConversations(String userId) async {
    return await client.from('conversations')
        .select('*, vendor_profiles(shop_name, shop_logo_url), profiles(full_name, avatar_url)')
        .or('buyer_id.eq.$userId,vendor_id.eq.$userId')
        .order('last_message_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String conversationId) async {
    return await client.from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  // Notifications
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId, {int limit = 20}) async {
    return await client.from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<void> markNotificationsRead(String userId) async {
    await client.from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Realtime subscriptions
  RealtimeChannel subscribeToMessages(String conversationId, Function(Map<String, dynamic>) onMessage) {
    return client.channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToNotifications(String userId, Function(Map<String, dynamic>) onNotification) {
    return client.channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) => onNotification(payload.newRecord),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToBids(String productId, Function(Map<String, dynamic>) onBid) {
    return client.channel('bids:$productId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bids',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'product_id', value: productId),
          callback: (payload) => onBid(payload.newRecord),
        )
        .subscribe();
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});
