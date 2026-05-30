-- ============================================================
-- AUTOX MARKETPLACE - SEED DATA
-- ============================================================

-- Categories
INSERT INTO categories (name, slug, icon, sort_order) VALUES
  ('Engine Parts',   'engine-parts',   '⚙️',  1),
  ('Brakes',         'brakes',         '🛑',  2),
  ('Suspension',     'suspension',     '🔩',  3),
  ('Exhaust',        'exhaust',        '💨',  4),
  ('Lighting',       'lighting',       '💡',  5),
  ('Body Kits',      'body-kits',      '🏎️',  6),
  ('Interior',       'interior',       '🪑',  7),
  ('Electronics',    'electronics',    '📟',  8),
  ('Wheels & Tyres', 'wheels-tyres',   '🛞',  9),
  ('Turbo & Forced', 'turbo-forced',   '💥', 10),
  ('Cooling',        'cooling',        '❄️',  11),
  ('Fuel System',    'fuel-system',    '⛽', 12);

-- CMS Pages
INSERT INTO cms_pages (title, slug, content, meta_title, meta_description) VALUES
  ('About Us',      'about',       '<h1>About AUTOX Marketplace</h1><p>The world''s premium auto parts exchange.</p>',
   'About AUTOX Marketplace', 'Learn about the world''s leading premium auto parts marketplace.'),
  ('Terms of Service', 'terms',   '<h1>Terms of Service</h1><p>By using AUTOX Marketplace you agree to these terms.</p>',
   'Terms of Service | AUTOX', 'Read the AUTOX Marketplace terms of service.'),
  ('Privacy Policy', 'privacy',   '<h1>Privacy Policy</h1><p>We take your privacy seriously.</p>',
   'Privacy Policy | AUTOX', 'Read how AUTOX protects your personal data.'),
  ('Escrow Policy',  'escrow-policy', '<h1>Escrow Policy</h1><p>All transactions are escrow-protected.</p>',
   'Escrow Policy | AUTOX', 'Understand how AUTOX escrow protection works.'),
  ('Refund Policy',  'refund-policy', '<h1>Refund Policy</h1><p>Buyers can request refunds within 30 days.</p>',
   'Refund Policy | AUTOX', 'Read the AUTOX Marketplace refund policy.'),
  ('FAQ',            'faq',           '<h1>Frequently Asked Questions</h1><p>Find answers to common questions.</p>',
   'FAQ | AUTOX Marketplace', 'Get answers to frequently asked questions about AUTOX Marketplace.');

-- Coin settings (already inserted via DEFAULT VALUES in schema, this updates it)
UPDATE coin_settings SET
  usd_rate              = 1.00,
  platform_fee_pct      = 3.50,
  withdrawal_fee_pct    = 1.50,
  min_topup             = 10,
  max_topup_daily       = 50000,
  withdrawal_cooldown_hours = 24;
