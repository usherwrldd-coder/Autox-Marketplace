-- ============================================================
-- AUTOX MARKETPLACE - TRIGGERS
-- ============================================================

-- Auto-create wallet on signup
CREATE OR REPLACE FUNCTION create_wallet_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO wallets (user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_wallet
  AFTER INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION create_wallet_on_signup();

-- Update product search vector
CREATE OR REPLACE FUNCTION update_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.brand, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(NEW.vehicle_make,'') || ' ' || COALESCE(NEW.vehicle_model,'')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_search
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();

-- Auto updated_at timestamps
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_updated_at_products  BEFORE UPDATE ON products  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_orders    BEFORE UPDATE ON orders    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_profiles  BEFORE UPDATE ON profiles  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_wallets   BEFORE UPDATE ON wallets   FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Auto-create escrow entry when order moves to in_escrow
CREATE OR REPLACE FUNCTION create_escrow_on_order()
RETURNS TRIGGER AS $$
DECLARE
  v_fee_pct    NUMERIC;
  v_fee_amount INTEGER;
BEGIN
  IF NEW.status = 'in_escrow' AND OLD.status = 'pending' THEN
    SELECT platform_fee_pct INTO v_fee_pct FROM coin_settings LIMIT 1;
    v_fee_amount := FLOOR(NEW.total_coins * v_fee_pct / 100);

    INSERT INTO escrow_entries (order_id, buyer_id, vendor_id, amount, fee_amount)
    VALUES (NEW.id, NEW.buyer_id, NEW.vendor_id, NEW.total_coins, v_fee_amount)
    ON CONFLICT (order_id) DO NOTHING;

    UPDATE wallets
    SET escrow_balance = escrow_balance + NEW.total_coins,
        balance        = balance        - NEW.total_coins
    WHERE user_id = NEW.buyer_id;

    INSERT INTO notifications (user_id, type, title, body, link)
    VALUES (NEW.vendor_id, 'order', 'New Order Received! 🛒',
      'Order ' || NEW.order_number || ' — ' || NEW.total_coins || ' AXC held in escrow.',
      '/vendor-panel/orders');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_escrow
  AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION create_escrow_on_order();

-- Release escrow when buyer confirms delivery
CREATE OR REPLACE FUNCTION release_escrow_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_escrow     escrow_entries%ROWTYPE;
  v_net_amount INTEGER;
BEGIN
  IF NEW.status = 'delivered' AND OLD.status = 'shipped' THEN
    SELECT * INTO v_escrow FROM escrow_entries WHERE order_id = NEW.id;
    v_net_amount := v_escrow.amount - v_escrow.fee_amount;

    -- Credit vendor wallet
    UPDATE wallets
    SET balance        = balance        + v_net_amount,
        pending_payout = pending_payout + v_net_amount,
        lifetime_spent = lifetime_spent + v_escrow.amount
    WHERE user_id = NEW.vendor_id;

    -- Deduct buyer escrow balance
    UPDATE wallets
    SET escrow_balance = escrow_balance - v_escrow.amount
    WHERE user_id = NEW.buyer_id;

    -- Mark escrow released
    UPDATE escrow_entries
    SET status = 'released', released_at = NOW()
    WHERE order_id = NEW.id;

    NEW.escrow_released    := TRUE;
    NEW.escrow_released_at := NOW();
    NEW.delivery_confirmed_at := NOW();

    -- Update vendor sales count
    UPDATE vendor_profiles SET total_sales = total_sales + 1 WHERE id = NEW.vendor_id;

    -- Record transaction for vendor
    INSERT INTO transactions (user_id, type, amount, balance_before, balance_after, reference_id, reference_type, description)
    SELECT NEW.vendor_id, 'escrow_release', v_net_amount,
      w.balance - v_net_amount, w.balance,
      NEW.id, 'order',
      'Escrow released for order ' || NEW.order_number
    FROM wallets w WHERE w.user_id = NEW.vendor_id;

    -- Notify vendor
    INSERT INTO notifications (user_id, type, title, body, link)
    VALUES (NEW.vendor_id, 'escrow', 'Escrow Released! 🎉',
      v_net_amount || ' AXC added to your wallet for order ' || NEW.order_number,
      '/vendor-panel/wallet');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_release_escrow
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION release_escrow_on_delivery();

-- Update winning bid on new bid
CREATE OR REPLACE FUNCTION update_winning_bid()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE bids SET is_winning = FALSE
  WHERE product_id = NEW.product_id AND is_winning = TRUE;

  NEW.is_winning := TRUE;

  UPDATE products
  SET current_bid = NEW.bid_amount,
      bid_count   = bid_count + 1
  WHERE id = NEW.product_id;

  -- Notify previously winning bidder they were outbid
  INSERT INTO notifications (user_id, type, title, body, link)
  SELECT b.bidder_id, 'bid', 'You''ve been outbid!',
    'Place a higher bid to stay in the auction.',
    '/auctions/' || NEW.product_id
  FROM bids b
  WHERE b.product_id = NEW.product_id
    AND b.is_winning = FALSE
    AND b.bidder_id != NEW.bidder_id
  ORDER BY b.bid_amount DESC
  LIMIT 1;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_winning_bid
  BEFORE INSERT ON bids
  FOR EACH ROW EXECUTE FUNCTION update_winning_bid();

-- Update conversation on new message
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message    = NEW.body,
      last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_conversation_last_msg
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();

-- Update category listing count
CREATE OR REPLACE FUNCTION update_category_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.is_approved = TRUE THEN
    UPDATE categories SET listing_count = listing_count + 1 WHERE id = NEW.category_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.is_approved != OLD.is_approved THEN
    IF NEW.is_approved = TRUE THEN
      UPDATE categories SET listing_count = listing_count + 1 WHERE id = NEW.category_id;
    ELSE
      UPDATE categories SET listing_count = listing_count - 1 WHERE id = NEW.category_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.is_approved = TRUE THEN
    UPDATE categories SET listing_count = listing_count - 1 WHERE id = OLD.category_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_count
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION update_category_count();
