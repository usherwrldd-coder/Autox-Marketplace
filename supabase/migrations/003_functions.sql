-- ============================================================
-- AUTOX MARKETPLACE - DATABASE FUNCTIONS
-- ============================================================

-- Full-text product search
CREATE OR REPLACE FUNCTION search_products(
  query_text    TEXT,
  cat_id        UUID    DEFAULT NULL,
  min_price     INTEGER DEFAULT NULL,
  max_price     INTEGER DEFAULT NULL,
  p_condition   TEXT    DEFAULT NULL,
  p_type        TEXT    DEFAULT NULL,
  vehicle_make  TEXT    DEFAULT NULL,
  vehicle_model TEXT    DEFAULT NULL,
  vehicle_year  INTEGER DEFAULT NULL,
  page_num      INTEGER DEFAULT 1,
  page_size     INTEGER DEFAULT 24
)
RETURNS TABLE (
  id UUID, title TEXT, slug TEXT, brand TEXT, price_coins INTEGER,
  condition product_condition, product_type product_type,
  images TEXT[], avg_rating NUMERIC, review_count INTEGER,
  vehicle_make TEXT, vehicle_model TEXT, is_auction BOOLEAN,
  auction_end TIMESTAMPTZ, current_bid INTEGER, bid_count INTEGER,
  vendor_id UUID, shop_name TEXT, is_verified BOOLEAN,
  rank REAL, total_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH results AS (
    SELECT
      p.id, p.title, p.slug, p.brand, p.price_coins,
      p.condition, p.product_type, p.images, p.avg_rating, p.review_count,
      p.vehicle_make, p.vehicle_model, p.is_auction, p.auction_end,
      p.current_bid, p.bid_count, p.vendor_id,
      v.shop_name, v.is_verified,
      ts_rank(p.search_vector, plainto_tsquery('english', query_text)) AS rank,
      COUNT(*) OVER() AS total_count
    FROM products p
    JOIN vendor_profiles v ON v.id = p.vendor_id
    WHERE
      p.is_active = TRUE AND p.is_approved = TRUE
      AND (query_text IS NULL OR query_text = '' OR p.search_vector @@ plainto_tsquery('english', query_text))
      AND (cat_id      IS NULL OR p.category_id = cat_id)
      AND (min_price   IS NULL OR p.price_coins >= min_price)
      AND (max_price   IS NULL OR p.price_coins <= max_price)
      AND (p_condition IS NULL OR p.condition::TEXT = p_condition)
      AND (p_type      IS NULL OR p.product_type::TEXT = p_type)
      AND (vehicle_make  IS NULL OR LOWER(p.vehicle_make)  LIKE LOWER('%' || vehicle_make  || '%'))
      AND (vehicle_model IS NULL OR LOWER(p.vehicle_model) LIKE LOWER('%' || vehicle_model || '%'))
      AND (vehicle_year  IS NULL OR (p.vehicle_year_from <= vehicle_year AND p.vehicle_year_to >= vehicle_year))
    ORDER BY rank DESC, p.created_at DESC
    LIMIT page_size OFFSET (page_num - 1) * page_size
  )
  SELECT * FROM results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get vendor dashboard stats
CREATE OR REPLACE FUNCTION get_vendor_stats(p_vendor_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_sales',     COALESCE(SUM(o.total_coins) FILTER (WHERE o.status = 'delivered'), 0),
    'total_orders',    COUNT(*) FILTER (WHERE o.status != 'cancelled'),
    'pending_orders',  COUNT(*) FILTER (WHERE o.status IN ('pending','in_escrow','shipped')),
    'in_escrow',       COALESCE(SUM(e.amount) FILTER (WHERE e.status = 'holding'), 0),
    'active_listings', (SELECT COUNT(*) FROM products WHERE vendor_id = p_vendor_id AND is_active = TRUE),
    'avg_rating',      COALESCE(AVG(pr.rating), 0)
  )
  INTO result
  FROM orders o
  LEFT JOIN escrow_entries e ON e.order_id = o.id
  LEFT JOIN product_reviews pr ON pr.order_id = o.id
  WHERE o.vendor_id = p_vendor_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get buyer dashboard stats
CREATE OR REPLACE FUNCTION get_buyer_stats(p_buyer_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_orders',    COUNT(*),
    'in_escrow',       COALESCE(SUM(e.amount) FILTER (WHERE e.status = 'holding'), 0),
    'active_bids',     (SELECT COUNT(*) FROM bids WHERE bidder_id = p_buyer_id AND status = 'active'),
    'wishlist_count',  (SELECT COUNT(*) FROM wishlists WHERE user_id = p_buyer_id),
    'total_spent',     COALESCE(SUM(o.total_coins) FILTER (WHERE o.status = 'delivered'), 0)
  )
  INTO result
  FROM orders o
  LEFT JOIN escrow_entries e ON e.order_id = o.id AND e.buyer_id = p_buyer_id
  WHERE o.buyer_id = p_buyer_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment helper
CREATE OR REPLACE FUNCTION increment(row_id UUID, amount INTEGER)
RETURNS INTEGER AS $$
  UPDATE wallets SET lifetime_topup = lifetime_topup + amount WHERE user_id = row_id
  RETURNING lifetime_topup;
$$ LANGUAGE sql SECURITY DEFINER;

-- Admin: get platform analytics
CREATE OR REPLACE FUNCTION get_admin_analytics(days_back INTEGER DEFAULT 30)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
  since  TIMESTAMPTZ := NOW() - (days_back || ' days')::INTERVAL;
BEGIN
  SELECT jsonb_build_object(
    'total_revenue',    COALESCE(SUM(t.amount) FILTER (WHERE t.type = 'topup' AND t.created_at >= since), 0),
    'platform_fees',    COALESCE(SUM(e.fee_amount) FILTER (WHERE e.released_at >= since), 0),
    'new_users',        (SELECT COUNT(*) FROM profiles WHERE created_at >= since),
    'new_vendors',      (SELECT COUNT(*) FROM vendor_profiles WHERE created_at >= since),
    'total_orders',     (SELECT COUNT(*) FROM orders WHERE created_at >= since),
    'escrow_volume',    COALESCE(SUM(e.amount), 0),
    'open_disputes',    (SELECT COUNT(*) FROM disputes WHERE status IN ('open','under_review')),
    'pending_kyc',      (SELECT COUNT(*) FROM profiles WHERE kyc_status = 'submitted'),
    'pending_refunds',  (SELECT COUNT(*) FROM refund_requests WHERE status = 'pending')
  )
  INTO result
  FROM transactions t
  LEFT JOIN escrow_entries e ON e.status = 'holding';

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
