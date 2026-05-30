-- TEST DATA FOR AUTOX MARKETPLACE
-- Run this in Supabase SQL Editor to populate test data

-- First, ensure we have a vendor profile from existing auth user
DO $$
DECLARE
  user_id UUID;
BEGIN
  -- Get the first user from auth.users
  SELECT id INTO user_id FROM auth.users LIMIT 1;
  
  IF user_id IS NULL THEN
    RAISE NOTICE 'No auth users found. Please create a user first.';
    RETURN;
  END IF;
  
  -- Create profile if not exists (without email column)
  INSERT INTO profiles (id, username, full_name, role, avatar_url, is_active)
  SELECT 
    id,
    COALESCE(raw_user_meta_data->>'username', split_part(email, '@', 1)),
    COALESCE(raw_user_meta_data->>'full_name', 'Test User'),
    'vendor',
    'https://ui-avatars.com/api/?name=Test+Vendor&background=random',
    true
  FROM auth.users WHERE id = user_id
  ON CONFLICT (id) DO UPDATE SET role = 'vendor';
  
  -- Create vendor profile if not exists
  INSERT INTO vendor_profiles (id, shop_name, shop_slug, shop_description, is_verified)
  VALUES (
    user_id,
    'ProParts Auto',
    'proparts-auto',
    'Premium auto parts supplier',
    true
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Also create a buyer profile if only one user exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id != user_id) THEN
    INSERT INTO auth.users (id, email, role)
    VALUES (
      gen_random_uuid(),
      'buyer@autox.com',
      'authenticated'
    );
  END IF;
END $$;

-- Insert test categories
INSERT INTO categories (name, slug, icon, sort_order) VALUES
  ('Engine Parts', 'engine-parts', '⚙️', 1),
  ('Brakes', 'brakes', '🛑', 2),
  ('Suspension', 'suspension', '🔩', 3),
  ('Exhaust', 'exhaust', '💨', 4),
  ('Lighting', 'lighting', '💡', 5),
  ('Body Kits', 'body-kits', '🏎️', 6),
  ('Interior', 'interior', '🪑', 7),
  ('Electronics', 'electronics', '📟', 8)
ON CONFLICT (slug) DO NOTHING;

-- Insert test products
INSERT INTO products (title, slug, description, price_coins, category_id, condition, product_type, images, quantity, vendor_id, is_active, is_approved) 
SELECT 
  v.title, v.slug, v.description, v.price, 
  c.id, 
  CASE v.condition 
    WHEN 'New' THEN 'new' 
    WHEN 'Used - Excellent' THEN 'used_excellent'
    WHEN 'Used - Good' THEN 'used_good'
    ELSE 'new' 
  END::product_condition,
  CASE v.product_type 
    WHEN 'buy_now' THEN 'buy_now' 
    WHEN 'auction' THEN 'auction'
    WHEN 'negotiable' THEN 'negotiable'
    ELSE 'buy_now' 
  END::product_type,
  ARRAY[v.image_url], v.stock, 
  (SELECT id FROM vendor_profiles LIMIT 1),
  true, true
FROM (VALUES
  ('Performance Brake Pads - Front', 'performance-brake-pads-front', 'High-performance ceramic brake pads for sport sedans.', 12999, 'brakes', 'New', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 50),
  ('Turbocharger Kit - Universal', 'turbocharger-kit-universal', 'Universal turbocharger kit for 4-cylinder engines.', 89999, 'engine-parts', 'New', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 12),
  ('LED Headlight Conversion Kit', 'led-headlight-conversion-kit', '6000K white LED headlight conversion kit.', 7999, 'lighting', 'New', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 200),
  ('Coilover Suspension Kit', 'coilover-suspension-kit', 'Adjustable coilover suspension kit with 32 damping levels.', 54999, 'suspension', 'New', 'auction', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 8),
  ('Cat-Back Exhaust System', 'cat-back-exhaust-system', 'Stainless steel cat-back exhaust with dual tips.', 34999, 'exhaust', 'New', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 25),
  ('Carbon Fiber Front Lip', 'carbon-fiber-front-lip', 'Universal carbon fiber front lip spoiler.', 19999, 'body-kits', 'New', 'negotiable', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 15),
  ('Sport Bucket Seats - Pair', 'sport-bucket-seats-pair', 'Reclinable sport bucket seats with lumbar support.', 44999, 'interior', 'Used - Excellent', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 3),
  ('Stand-alone ECU', 'stand-alone-ecu', 'Programmable engine management system.', 69999, 'electronics', 'New', 'buy_now', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', 20)
) AS v(title, slug, description, price, category_slug, condition, product_type, image_url, stock)
JOIN categories c ON c.slug = v.category_slug
ON CONFLICT (slug) DO NOTHING;

-- Update marketplace settings with bank info
INSERT INTO marketplace_settings (key, value) VALUES
  ('bank_name', '"Lead Bank"'),
  ('bank_account_name', '"AUTOX Marketplace LLC"'),
  ('bank_account_number', '"212519935049"'),
  ('bank_routing_number', '"101019644"'),
  ('bank_wire_routing_number', '"101019644"'),
  ('bank_address', '"1801 Main Street, Kansas City, MO 64108"'),
  ('deposit_instructions', '"Transfer the exact amount to the account above. Include your reference number in the transfer memo. Upload proof of payment to complete the deposit."')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();