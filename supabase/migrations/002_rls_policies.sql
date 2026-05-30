-- ============================================================
-- AUTOX MARKETPLACE - ROW LEVEL SECURITY POLICIES
-- ============================================================

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews   ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE escrow_entries    ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids              ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists         ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts           ENABLE ROW LEVEL SECURITY;

-- HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT role IN ('admin','moderator') FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_vendor()
RETURNS BOOLEAN AS $$
  SELECT role = 'vendor' FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- PROFILES
CREATE POLICY "profiles_select_public"    ON profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_update_own"       ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_on_signup" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "admin_all_profiles"        ON profiles FOR ALL USING (is_admin());

-- ADDRESSES
CREATE POLICY "addresses_own" ON addresses FOR ALL USING (auth.uid() = user_id);

-- VENDOR PROFILES
CREATE POLICY "vendor_profiles_public"  ON vendor_profiles FOR SELECT USING (TRUE);
CREATE POLICY "vendor_profiles_own"     ON vendor_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "vendor_profiles_insert"  ON vendor_profiles FOR INSERT WITH CHECK (auth.uid() = id AND is_vendor());
CREATE POLICY "vendor_profiles_admin"   ON vendor_profiles FOR ALL USING (is_admin());

-- WALLETS (mutated only via Edge Functions)
CREATE POLICY "wallets_own_select" ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "wallets_admin"      ON wallets FOR ALL    USING (is_admin());

-- TRANSACTIONS
CREATE POLICY "tx_own_select" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tx_admin"      ON transactions FOR ALL    USING (is_admin());

-- PRODUCTS
CREATE POLICY "products_public_select"  ON products FOR SELECT
  USING (is_approved = TRUE AND is_active = TRUE);
CREATE POLICY "products_vendor_own"     ON products FOR SELECT
  USING (auth.uid() = vendor_id);
CREATE POLICY "products_vendor_insert"  ON products FOR INSERT
  WITH CHECK (auth.uid() = vendor_id AND is_vendor());
CREATE POLICY "products_vendor_update"  ON products FOR UPDATE
  USING (auth.uid() = vendor_id);
CREATE POLICY "products_admin"          ON products FOR ALL USING (is_admin());

-- PRODUCT REVIEWS
CREATE POLICY "reviews_public"  ON product_reviews FOR SELECT USING (TRUE);
CREATE POLICY "reviews_own"     ON product_reviews FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "reviews_admin"   ON product_reviews FOR ALL USING (is_admin());

-- ORDERS
CREATE POLICY "orders_buyer_select"  ON orders FOR SELECT USING (auth.uid() = buyer_id);
CREATE POLICY "orders_vendor_select" ON orders FOR SELECT
  USING (auth.uid() IN (SELECT id FROM vendor_profiles WHERE id = vendor_id));
CREATE POLICY "orders_buyer_insert"  ON orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "orders_admin"         ON orders FOR ALL USING (is_admin());

-- ESCROW ENTRIES
CREATE POLICY "escrow_buyer"  ON escrow_entries FOR SELECT USING (auth.uid() = buyer_id);
CREATE POLICY "escrow_vendor" ON escrow_entries FOR SELECT USING (auth.uid() = vendor_id);
CREATE POLICY "escrow_admin"  ON escrow_entries FOR ALL USING (is_admin());

-- REFUND REQUESTS
CREATE POLICY "refunds_buyer"  ON refund_requests FOR SELECT USING (auth.uid() = buyer_id);
CREATE POLICY "refunds_create" ON refund_requests FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "refunds_admin"  ON refund_requests FOR ALL USING (is_admin());

-- OFFERS
CREATE POLICY "offers_buyer"   ON offers FOR SELECT USING (auth.uid() = buyer_id);
CREATE POLICY "offers_vendor"  ON offers FOR SELECT USING (auth.uid() = vendor_id);
CREATE POLICY "offers_create"  ON offers FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "offers_respond" ON offers FOR UPDATE USING (auth.uid() = vendor_id);
CREATE POLICY "offers_admin"   ON offers FOR ALL USING (is_admin());

-- BIDS
CREATE POLICY "bids_public"  ON bids FOR SELECT USING (TRUE);
CREATE POLICY "bids_own"     ON bids FOR SELECT USING (auth.uid() = bidder_id);
CREATE POLICY "bids_create"  ON bids FOR INSERT WITH CHECK (auth.uid() = bidder_id);
CREATE POLICY "bids_admin"   ON bids FOR ALL USING (is_admin());

-- CONVERSATIONS & MESSAGES
CREATE POLICY "conv_participant" ON conversations FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() = vendor_id);
CREATE POLICY "conv_create"      ON conversations FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "conv_admin"       ON conversations FOR ALL USING (is_admin());

CREATE POLICY "messages_participant" ON messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE buyer_id = auth.uid() OR vendor_id = auth.uid()
    )
  );
CREATE POLICY "messages_send"  ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages_admin" ON messages FOR ALL USING (is_admin());

-- NOTIFICATIONS
CREATE POLICY "notifs_own"        ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifs_update_own" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "notifs_admin"      ON notifications FOR ALL USING (is_admin());

-- WISHLISTS
CREATE POLICY "wishlist_own"   ON wishlists FOR ALL USING (auth.uid() = user_id);

-- DISPUTES
CREATE POLICY "disputes_participant" ON disputes FOR SELECT
  USING (auth.uid() = opened_by OR auth.uid() = against);
CREATE POLICY "disputes_create" ON disputes FOR INSERT WITH CHECK (auth.uid() = opened_by);
CREATE POLICY "disputes_admin"  ON disputes FOR ALL USING (is_admin());

-- PAYOUTS
CREATE POLICY "payouts_vendor" ON payouts FOR SELECT
  USING (auth.uid() IN (SELECT id FROM vendor_profiles WHERE id = vendor_id));
CREATE POLICY "payouts_admin"  ON payouts FOR ALL USING (is_admin());
