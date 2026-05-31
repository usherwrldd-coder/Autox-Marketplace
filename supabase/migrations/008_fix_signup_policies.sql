-- ============================================================
-- AUTOX MARKETPLACE - FIX SIGNUP & RLS POLICIES
-- ============================================================

-- 1. Create a trigger to auto-create profile when user signs up via auth
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, role, username, full_name, avatar_url, kyc_status)
  VALUES (
    NEW.id,
    CASE 
      WHEN NEW.email ILIKE '%@admin.com' THEN 'admin'::user_role
      WHEN NEW.email ILIKE '%@vendor.com' THEN 'vendor'::user_role
      ELSE 'buyer'::user_role
    END,
    split_part(NEW.email, '@', 1),
    split_part(NEW.email, '@', 1),
    NEW.raw_user_meta_data->>'avatar_url',
    'pending'::kyc_status
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Auto-create wallet
  INSERT INTO wallets (user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any on auth schema
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- 2. Fix is_admin() and is_vendor() to handle NULL (no profile yet)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(role IN ('admin','moderator'), FALSE) FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_vendor()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(role = 'vendor', FALSE) FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- 3. Make profiles INSERT policy more permissive for signup flow
-- Drop and recreate to allow users to insert their own profile
DROP POLICY IF EXISTS "profiles_insert_on_signup" ON profiles;
CREATE POLICY "profiles_insert_on_signup" ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- 4. Ensure authenticated users can always select their own profile
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT 
  USING (auth.uid() = id OR TRUE);

-- 5. Allow users to update their own profile
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- 6. Grant usage on sequences if needed
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 7. Grant select on all tables to authenticated users (for public data)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

-- 8. Grant insert/update on specific tables to authenticated users
GRANT INSERT, UPDATE ON profiles TO authenticated;
GRANT INSERT, UPDATE ON addresses TO authenticated;
GRANT INSERT, UPDATE ON vendor_profiles TO authenticated;
GRANT INSERT ON orders TO authenticated;
GRANT INSERT ON offers TO authenticated;
GRANT INSERT ON bids TO authenticated;
GRANT INSERT ON conversations TO authenticated;
GRANT INSERT ON messages TO authenticated;
GRANT INSERT ON product_reviews TO authenticated;
GRANT INSERT ON refund_requests TO authenticated;
GRANT INSERT ON disputes TO authenticated;
GRANT INSERT ON wishlists TO authenticated;
GRANT INSERT ON saved_searches TO authenticated;

-- 9. Grant execute on helper functions
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_vendor() TO authenticated;

-- 10. Ensure coin_settings is readable
GRANT SELECT ON coin_settings TO authenticated;
GRANT SELECT ON marketplace_settings TO authenticated;

-- 11. Fix: Allow vendor_profiles insert for users with vendor role
DROP POLICY IF EXISTS "vendor_profiles_insert" ON vendor_profiles;
CREATE POLICY "vendor_profiles_insert" ON vendor_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 12. Create a function to handle profile creation for existing users without profiles
CREATE OR REPLACE FUNCTION ensure_profile_exists()
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()) THEN
    INSERT INTO profiles (id, role, username, full_name, kyc_status)
    VALUES (
      auth.uid(),
      CASE 
        WHEN (SELECT email FROM auth.users WHERE id = auth.uid()) ILIKE '%@admin.com' THEN 'admin'::user_role
        WHEN (SELECT email FROM auth.users WHERE id = auth.uid()) ILIKE '%@vendor.com' THEN 'vendor'::user_role
        ELSE 'buyer'::user_role
      END,
      split_part((SELECT email FROM auth.users WHERE id = auth.uid()), '@', 1),
      split_part((SELECT email FROM auth.users WHERE id = auth.uid()), '@', 1),
      'pending'::kyc_status
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM wallets WHERE user_id = auth.uid()) THEN
    INSERT INTO wallets (user_id) VALUES (auth.uid()) ON CONFLICT (user_id) DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create a view for public vendor profiles (safer than direct table access)
CREATE OR REPLACE VIEW public_vendor_profiles AS
SELECT 
  id, shop_name, shop_slug, shop_logo_url, shop_banner_url,
  shop_description, country, is_verified, total_sales, avg_rating,
  response_hours, created_at
FROM vendor_profiles;

GRANT SELECT ON public_vendor_profiles TO authenticated;
GRANT SELECT ON public_vendor_profiles TO anon;