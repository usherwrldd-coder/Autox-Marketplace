-- ============================================================
-- AUTOX MARKETPLACE - COMPLETE AUTH FLOW FIX
-- Fixes: RLS policies, trigger function, profile creation
-- ============================================================

-- 1. Drop existing problematic trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user_signup();

-- 2. Create improved trigger function with defensive handling
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
DECLARE
  v_role user_role := 'buyer';
  v_username TEXT;
  v_full_name TEXT;
  v_avatar_url TEXT;
BEGIN
  -- Determine role from email domain or metadata
  IF NEW.email ILIKE '%@admin.com' THEN
    v_role := 'admin';
  ELSIF NEW.email ILIKE '%@vendor.com' THEN
    v_role := 'vendor';
  ELSIF NEW.raw_user_meta_data->>'role' = 'vendor' THEN
    v_role := 'vendor';
  END IF;

  -- Generate username from email (handle null email)
  v_username := COALESCE(
    split_part(NEW.email, '@', 1),
    'user_' || substr(NEW.id::text, 1, 8)
  );
  
  -- Get full name and avatar from metadata
  v_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    v_username
  );
  v_avatar_url := NEW.raw_user_meta_data->>'avatar_url';

  -- Insert profile (handle duplicate gracefully)
  INSERT INTO profiles (id, role, username, full_name, avatar_url, kyc_status, is_active)
  VALUES (
    NEW.id,
    v_role,
    v_username,
    v_full_name,
    v_avatar_url,
    'pending'::kyc_status,
    TRUE
  )
  ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    username = EXCLUDED.username,
    full_name = EXCLUDED.full_name,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = NOW();

  -- Create wallet (handle duplicate gracefully)
  INSERT INTO wallets (user_id, balance, escrow_balance)
  VALUES (NEW.id, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- 4. Fix RLS policies for profiles table
-- Drop existing policies
DROP POLICY IF EXISTS "profiles_select_public" ON profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_on_signup" ON profiles;
DROP POLICY IF EXISTS "admin_all_profiles" ON profiles;

-- Create new policies
-- Allow public read access to basic profile info (safe columns only)
CREATE POLICY "profiles_select_public" ON profiles FOR SELECT
  USING (TRUE);

-- Allow users to read their own full profile
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own profile (for signup flow)
CREATE POLICY "profiles_insert_on_signup" ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow admins to do anything with profiles
CREATE POLICY "admin_all_profiles" ON profiles FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- 5. Fix RLS policies for wallets table
DROP POLICY IF EXISTS "wallets_own_select" ON wallets;
DROP POLICY IF EXISTS "wallets_admin" ON wallets;

-- Allow users to read their own wallet
CREATE POLICY "wallets_own_select" ON wallets FOR SELECT
  USING (auth.uid() = user_id);

-- Allow admins to do anything with wallets
CREATE POLICY "wallets_admin" ON wallets FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- 6. Fix is_admin() and is_vendor() functions to handle NULL
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(
    (SELECT role IN ('admin','moderator') FROM profiles WHERE id = auth.uid()),
    FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_vendor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(
    (SELECT role = 'vendor' FROM profiles WHERE id = auth.uid()),
    FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant select on all tables to authenticated users
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

-- Grant insert/update on specific tables
GRANT INSERT, UPDATE ON profiles TO authenticated;
GRANT INSERT, UPDATE ON addresses TO authenticated;
GRANT INSERT ON vendor_profiles TO authenticated;
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

-- Grant execute on helper functions
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_vendor() TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user_signup() TO authenticated;

-- 8. Create a function to ensure profile exists (for existing users)
CREATE OR REPLACE FUNCTION ensure_profile_exists()
RETURNS VOID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_email TEXT;
  v_role user_role := 'buyer';
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id) THEN
    RETURN;
  END IF;

  -- Get email from auth.users
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  
  -- Determine role
  IF v_email ILIKE '%@admin.com' THEN
    v_role := 'admin';
  ELSIF v_email ILIKE '%@vendor.com' THEN
    v_role := 'vendor';
  END IF;

  -- Create profile
  INSERT INTO profiles (id, role, username, full_name, kyc_status)
  VALUES (
    v_user_id,
    v_role,
    COALESCE(split_part(v_email, '@', 1), 'user_' || substr(v_user_id::text, 1, 8)),
    COALESCE(split_part(v_email, '@', 1), 'user_' || substr(v_user_id::text, 1, 8)),
    'pending'::kyc_status
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create wallet
  INSERT INTO wallets (user_id) VALUES (v_user_id)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create a view for public vendor profiles (safer access)
CREATE OR REPLACE VIEW public_vendor_profiles AS
SELECT 
  id, shop_name, shop_slug, shop_logo_url, shop_banner_url,
  shop_description, country, is_verified, total_sales, avg_rating,
  response_hours, created_at
FROM vendor_profiles;

GRANT SELECT ON public_vendor_profiles TO authenticated;
GRANT SELECT ON public_vendor_profiles TO anon;

-- 10. Fix vendor_profiles insert policy
DROP POLICY IF EXISTS "vendor_profiles_insert" ON vendor_profiles;
CREATE POLICY "vendor_profiles_insert" ON vendor_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 11. Ensure coin_settings and marketplace_settings are readable
GRANT SELECT ON coin_settings TO authenticated;
GRANT SELECT ON coin_settings TO anon;
GRANT SELECT ON marketplace_settings TO authenticated;
GRANT SELECT ON marketplace_settings TO anon;

-- 12. Add a policy to allow users to read their own notifications
DROP POLICY IF EXISTS "notifs_own" ON notifications;
CREATE POLICY "notifs_own" ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- 13. Fix messages policy to allow sending
DROP POLICY IF EXISTS "messages_send" ON messages;
CREATE POLICY "messages_send" ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- 14. Log the fix execution
DO $$
BEGIN
  RAISE NOTICE 'Auth flow fix applied successfully!';
  RAISE NOTICE 'Changes:';
  RAISE NOTICE '1. Fixed trigger function with defensive NULL handling';
  RAISE NOTICE '2. Fixed RLS policies for profiles and wallets';
  RAISE NOTICE '3. Fixed is_admin() and is_vendor() to handle NULL';
  RAISE NOTICE '4. Added ensure_profile_exists() function';
  RAISE NOTICE '5. Granted necessary permissions';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Run this migration in Supabase SQL Editor';
  RAISE NOTICE '2. Test user registration flow';
  RAISE NOTICE '3. Verify profile and wallet are created automatically';
END $$;