-- ============================================================
-- AUTOX MARKETPLACE - COMPLETE POSTGRESQL SCHEMA
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ENUMS
CREATE TYPE user_role         AS ENUM ('buyer','vendor','admin','moderator');
CREATE TYPE product_type      AS ENUM ('buy_now','negotiable','auction');
CREATE TYPE product_condition AS ENUM ('new','used_excellent','used_good','used_fair','refurbished');
CREATE TYPE order_status      AS ENUM ('pending','in_escrow','shipped','delivered','disputed','refunded','cancelled');
CREATE TYPE tx_type           AS ENUM ('topup','purchase','escrow_hold','escrow_release','refund','withdrawal','fee');
CREATE TYPE offer_status      AS ENUM ('pending','accepted','rejected','countered','expired');
CREATE TYPE bid_status        AS ENUM ('active','won','lost','cancelled');
CREATE TYPE kyc_status        AS ENUM ('pending','submitted','approved','rejected');
CREATE TYPE refund_status     AS ENUM ('pending','approved','rejected','partial');
CREATE TYPE notif_type        AS ENUM ('order','offer','bid','message','escrow','refund','system');

-- PROFILES
CREATE TABLE profiles (
  id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role              user_role   NOT NULL DEFAULT 'buyer',
  username          TEXT        UNIQUE,
  full_name         TEXT,
  avatar_url        TEXT,
  phone             TEXT,
  bio               TEXT,
  kyc_status        kyc_status  NOT NULL DEFAULT 'pending',
  kyc_doc_url       TEXT,
  is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
  is_suspended      BOOLEAN     NOT NULL DEFAULT FALSE,
  suspension_reason TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE addresses (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label       TEXT NOT NULL DEFAULT 'Home',
  full_name   TEXT NOT NULL,
  line1       TEXT NOT NULL,
  line2       TEXT,
  city        TEXT NOT NULL,
  state       TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country     TEXT NOT NULL DEFAULT 'US',
  phone       TEXT,
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vendor_profiles (
  id               UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  shop_name        TEXT NOT NULL UNIQUE,
  shop_slug        TEXT NOT NULL UNIQUE,
  shop_logo_url    TEXT,
  shop_banner_url  TEXT,
  shop_description TEXT,
  country          TEXT,
  is_verified      BOOLEAN     NOT NULL DEFAULT FALSE,
  verified_at      TIMESTAMPTZ,
  verified_by      UUID REFERENCES profiles(id),
  total_sales      INTEGER     NOT NULL DEFAULT 0,
  avg_rating       NUMERIC(3,2) NOT NULL DEFAULT 0,
  response_hours   INTEGER     NOT NULL DEFAULT 24,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT    NOT NULL UNIQUE,
  slug          TEXT    NOT NULL UNIQUE,
  icon          TEXT,
  parent_id     UUID REFERENCES categories(id),
  listing_count INTEGER NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE products (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id         UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  category_id       UUID NOT NULL REFERENCES categories(id),
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  description       TEXT,
  brand             TEXT,
  sku               TEXT,
  condition         product_condition NOT NULL DEFAULT 'new',
  product_type      product_type      NOT NULL DEFAULT 'buy_now',
  price_coins       INTEGER NOT NULL CHECK (price_coins > 0),
  is_negotiable     BOOLEAN NOT NULL DEFAULT FALSE,
  is_auction        BOOLEAN NOT NULL DEFAULT FALSE,
  auction_start     TIMESTAMPTZ,
  auction_end       TIMESTAMPTZ,
  reserve_price     INTEGER,
  current_bid       INTEGER,
  bid_count         INTEGER NOT NULL DEFAULT 0,
  quantity          INTEGER NOT NULL DEFAULT 1,
  sold_count        INTEGER NOT NULL DEFAULT 0,
  images            TEXT[]  NOT NULL DEFAULT '{}',
  video_url         TEXT,
  tags              TEXT[]  DEFAULT '{}',
  warranty_info     TEXT,
  weight_kg         NUMERIC(8,2),
  vehicle_make      TEXT,
  vehicle_model     TEXT,
  vehicle_year_from INTEGER,
  vehicle_year_to   INTEGER,
  meta_title        TEXT,
  meta_description  TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  is_approved       BOOLEAN NOT NULL DEFAULT FALSE,
  approved_by       UUID REFERENCES profiles(id),
  is_featured       BOOLEAN NOT NULL DEFAULT FALSE,
  view_count        INTEGER NOT NULL DEFAULT 0,
  wishlist_count    INTEGER NOT NULL DEFAULT 0,
  avg_rating        NUMERIC(3,2) NOT NULL DEFAULT 0,
  review_count      INTEGER NOT NULL DEFAULT 0,
  shipping_from     TEXT,
  ships_worldwide   BOOLEAN NOT NULL DEFAULT FALSE,
  search_vector     TSVECTOR,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_search   ON products USING GIN(search_vector);
CREATE INDEX idx_products_tags     ON products USING GIN(tags);
CREATE INDEX idx_products_vendor   ON products(vendor_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_price    ON products(price_coins);
CREATE INDEX idx_products_auction  ON products(auction_end) WHERE is_auction = TRUE;

CREATE TABLE product_images (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID    NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  url        TEXT    NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE product_reviews (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id    UUID     NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  buyer_id      UUID     NOT NULL REFERENCES profiles(id),
  order_id      UUID     NOT NULL,
  rating        SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title         TEXT,
  body          TEXT,
  images        TEXT[],
  is_verified   BOOLEAN NOT NULL DEFAULT TRUE,
  helpful_count INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(product_id, buyer_id, order_id)
);

CREATE TABLE shipping_options (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id   UUID    NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  label        TEXT    NOT NULL,
  carrier      TEXT,
  est_days_min INTEGER,
  est_days_max INTEGER,
  price_coins  INTEGER NOT NULL DEFAULT 0,
  is_free      BOOLEAN NOT NULL DEFAULT FALSE
);

-- WALLET & COINS
CREATE TABLE wallets (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID    NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  balance        INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
  escrow_balance INTEGER NOT NULL DEFAULT 0 CHECK (escrow_balance >= 0),
  pending_payout INTEGER NOT NULL DEFAULT 0 CHECK (pending_payout >= 0),
  lifetime_topup INTEGER NOT NULL DEFAULT 0,
  lifetime_spent INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transactions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID    NOT NULL REFERENCES profiles(id),
  type              tx_type NOT NULL,
  amount            INTEGER NOT NULL,
  balance_before    INTEGER NOT NULL,
  balance_after     INTEGER NOT NULL,
  reference_id      UUID,
  reference_type    TEXT,
  description       TEXT    NOT NULL,
  metadata          JSONB   DEFAULT '{}',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_user ON transactions(user_id, created_at DESC);

CREATE TABLE coin_settings (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usd_rate                  NUMERIC(10,4) NOT NULL DEFAULT 1.0,
  platform_fee_pct          NUMERIC(5,2)  NOT NULL DEFAULT 3.5,
  withdrawal_fee_pct        NUMERIC(5,2)  NOT NULL DEFAULT 1.5,
  min_topup                 INTEGER       NOT NULL DEFAULT 10,
  max_topup_daily           INTEGER       NOT NULL DEFAULT 50000,
  withdrawal_cooldown_hours INTEGER       NOT NULL DEFAULT 24,
  updated_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

INSERT INTO coin_settings DEFAULT VALUES;

-- ORDERS & ESCROW
CREATE TABLE orders (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number          TEXT NOT NULL UNIQUE DEFAULT 'AX-' || FLOOR(RANDOM()*9000000+1000000)::TEXT,
  buyer_id              UUID NOT NULL REFERENCES profiles(id),
  vendor_id             UUID NOT NULL REFERENCES vendor_profiles(id),
  product_id            UUID NOT NULL REFERENCES products(id),
  status                order_status NOT NULL DEFAULT 'pending',
  quantity              INTEGER NOT NULL DEFAULT 1,
  unit_price            INTEGER NOT NULL,
  shipping_cost         INTEGER NOT NULL DEFAULT 0,
  platform_fee          INTEGER NOT NULL DEFAULT 0,
  total_coins           INTEGER NOT NULL,
  escrow_released       BOOLEAN NOT NULL DEFAULT FALSE,
  escrow_released_at    TIMESTAMPTZ,
  shipping_address      JSONB,
  shipping_option       JSONB,
  tracking_number       TEXT,
  tracking_carrier      TEXT,
  shipped_at            TIMESTAMPTZ,
  delivered_at          TIMESTAMPTZ,
  delivery_confirmed_at TIMESTAMPTZ,
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_buyer  ON orders(buyer_id,  created_at DESC);
CREATE INDEX idx_orders_vendor ON orders(vendor_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(status);

CREATE TABLE escrow_entries (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id    UUID NOT NULL UNIQUE REFERENCES orders(id),
  buyer_id    UUID NOT NULL REFERENCES profiles(id),
  vendor_id   UUID NOT NULL REFERENCES profiles(id),
  amount      INTEGER NOT NULL,
  fee_amount  INTEGER NOT NULL DEFAULT 0,
  status      TEXT    NOT NULL DEFAULT 'holding' CHECK (status IN ('holding','released','refunded','disputed')),
  held_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  released_at TIMESTAMPTZ,
  released_by UUID REFERENCES profiles(id),
  notes       TEXT
);

CREATE TABLE refund_requests (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id         UUID          NOT NULL REFERENCES orders(id),
  buyer_id         UUID          NOT NULL REFERENCES profiles(id),
  reason           TEXT          NOT NULL,
  details          TEXT,
  evidence_urls    TEXT[],
  amount_requested INTEGER       NOT NULL,
  amount_approved  INTEGER,
  status           refund_status NOT NULL DEFAULT 'pending',
  reviewed_by      UUID REFERENCES profiles(id),
  reviewed_at      TIMESTAMPTZ,
  admin_notes      TEXT,
  created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- OFFERS & BIDS
CREATE TABLE offers (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id    UUID         NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  buyer_id      UUID         NOT NULL REFERENCES profiles(id),
  vendor_id     UUID         NOT NULL REFERENCES vendor_profiles(id),
  offered_coins INTEGER      NOT NULL CHECK (offered_coins > 0),
  counter_coins INTEGER,
  status        offer_status NOT NULL DEFAULT 'pending',
  message       TEXT,
  expires_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW() + INTERVAL '48 hours',
  responded_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE bids (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id   UUID       NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  bidder_id    UUID       NOT NULL REFERENCES profiles(id),
  bid_amount   INTEGER    NOT NULL CHECK (bid_amount > 0),
  status       bid_status NOT NULL DEFAULT 'active',
  is_winning   BOOLEAN    NOT NULL DEFAULT FALSE,
  auto_bid_max INTEGER,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bids_product ON bids(product_id, bid_amount DESC);
CREATE INDEX idx_bids_bidder  ON bids(bidder_id);

-- MESSAGING
CREATE TABLE conversations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  buyer_id        UUID NOT NULL REFERENCES profiles(id),
  vendor_id       UUID NOT NULL REFERENCES vendor_profiles(id),
  product_id      UUID REFERENCES products(id),
  last_message    TEXT,
  last_message_at TIMESTAMPTZ,
  buyer_unread    INTEGER NOT NULL DEFAULT 0,
  vendor_unread   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(buyer_id, vendor_id, product_id)
);

CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID    NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID    NOT NULL REFERENCES profiles(id),
  body            TEXT,
  image_url       TEXT,
  offer_id        UUID REFERENCES offers(id),
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at DESC);

-- NOTIFICATIONS
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID       NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type       notif_type NOT NULL,
  title      TEXT       NOT NULL,
  body       TEXT       NOT NULL,
  link       TEXT,
  image_url  TEXT,
  is_read    BOOLEAN    NOT NULL DEFAULT FALSE,
  metadata   JSONB      DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifs_user ON notifications(user_id, created_at DESC);

-- WISHLISTS
CREATE TABLE wishlists (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

CREATE TABLE saved_searches (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  query      TEXT,
  filters    JSONB   DEFAULT '{}',
  alert_new  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DISPUTES
CREATE TABLE disputes (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id      UUID NOT NULL REFERENCES orders(id),
  opened_by     UUID NOT NULL REFERENCES profiles(id),
  against       UUID NOT NULL REFERENCES profiles(id),
  reason        TEXT NOT NULL,
  details       TEXT,
  evidence_urls TEXT[],
  status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','under_review','resolved','escalated')),
  resolution    TEXT,
  resolved_by   UUID REFERENCES profiles(id),
  resolved_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PAYOUTS
CREATE TABLE payouts (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id        UUID    NOT NULL REFERENCES vendor_profiles(id),
  amount           INTEGER NOT NULL CHECK (amount > 0),
  fee_amount       INTEGER NOT NULL DEFAULT 0,
  net_amount       INTEGER NOT NULL,
  status           TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed')),
  paypal_email     TEXT    NOT NULL,
  paypal_payout_id TEXT,
  processed_at     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- BLOG & CMS
CREATE TABLE blog_posts (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id        UUID    NOT NULL REFERENCES profiles(id),
  title            TEXT    NOT NULL,
  slug             TEXT    NOT NULL UNIQUE,
  excerpt          TEXT,
  content          TEXT    NOT NULL,
  cover_image      TEXT,
  tags             TEXT[],
  meta_title       TEXT,
  meta_description TEXT,
  is_published     BOOLEAN NOT NULL DEFAULT FALSE,
  published_at     TIMESTAMPTZ,
  view_count       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cms_pages (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title            TEXT    NOT NULL,
  slug             TEXT    NOT NULL UNIQUE,
  content          TEXT    NOT NULL,
  meta_title       TEXT,
  meta_description TEXT,
  is_published     BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ADMIN CONFIG
CREATE TABLE marketplace_settings (
  key        TEXT PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO marketplace_settings (key, value) VALUES
  ('site_name',              '"AUTOX Marketplace"'),
  ('maintenance_mode',       'false'),
  ('featured_limit',         '12'),
  ('max_images_per_product', '8');

CREATE TABLE featured_listings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  position   INTEGER NOT NULL,
  starts_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at    TIMESTAMPTZ NOT NULL,
  created_by UUID REFERENCES profiles(id)
);
