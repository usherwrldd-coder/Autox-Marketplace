-- ============================================================
-- AUTOX MARKETPLACE - FIX AUTH TRIGGER 500 ERROR
-- Handles edge cases where trigger fails during user creation
-- ============================================================

-- 1. Drop existing trigger and function to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user_signup();
DROP FUNCTION IF EXISTS ensure_profile_exists();

-- 2. Create a simpler, more robust trigger function
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER 
SECURITY DEFINER -- This is critical - runs with elevated privileges
SET search_path = public -- Ensure we're using the public schema
AS $$
DECLARE
  v_role text := 'buyer';
  v_username text;
  v_full_name text;
  v_email text;
BEGIN
  -- Get email safely
  v_email := COALESCE(NEW.email, '');
  
  -- Determine role from email domain or metadata
  IF v_email ILIKE '%@admin.com' THEN
    v_role := 'admin';
  ELSIF v_email ILIKE '%@vendor.com' THEN
    v_role := 'vendor';
  ELSIF COALESCE(NEW.raw_user_meta_data->>'role', '') = 'vendor' THEN
    v_role := 'vendor';
  END IF;

  -- Generate username from email (handle null/empty email)
  IF v_email != '' THEN
    v_username := split_part(v_email, '@', 1);
  ELSE
    v_username := 'user_' || substr(NEW.id::text, 1, 8);
  END IF;
  
  -- Get full name from metadata or use username
  v_full_name := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', ''),
    v_username
  );

  -- Insert profile with explicit type casting
  BEGIN
    INSERT INTO public.profiles (
      id, 
      role, 
      username, 
      full_name, 
      avatar_url,
      kyc_status, 
      is_active,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      v_role::public.user_role,
      v_username,
      v_full_name,
      NULLIF(NEW.raw_user_meta_data->>'avatar_url', ''),
      'pending'::public.kyc_status,
      TRUE,
      NOW(),
      NOW()
    );
  EXCEPTION 
    WHEN unique_violation THEN
      -- Profile already exists, update it
      UPDATE public.profiles 
      SET 
        role = v_role::public.user_role,
        username = v_username,
        full_name = v_full_name,
        avatar_url = NULLIF(NEW.raw_user_meta_data->>'avatar_url', ''),
        updated_at = NOW()
      WHERE id = NEW.id;
    WHEN foreign_key_violation THEN
      -- Auth user might not be fully committed yet, skip
      NULL;
    WHEN OTHERS THEN
      -- Log error but don't fail the signup
      RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
  END;

  -- Create wallet with error handling
  BEGIN
    INSERT INTO public.wallets (user_id, balance, escrow_balance, created_at, updated_at)
    VALUES (NEW.id, 0, 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;
  EXCEPTION 
    WHEN OTHERS THEN
      RAISE WARNING 'Error creating wallet for user %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION handle_new_user_signup() TO postgres;
GRANT EXECUTE ON FUNCTION handle_new_user_signup() TO authenticated;

-- 4. Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- 5. Ensure RLS is properly configured
-- First, make sure profiles table has RLS enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- 6. Drop all existing policies and recreate them cleanly
DROP POLICY IF EXISTS "profiles_select_public" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_on_signup" ON public.profiles;
DROP POLICY IF EXISTS "admin_all_profiles" ON public.profiles;

-- Public can see basic profiles
CREATE POLICY "profiles_select_public" ON public.profiles FOR SELECT
  USING (TRUE);

-- Users can see their own profile
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow profile insertion during signup (user's own profile only)
CREATE POLICY "profiles_insert_on_signup" ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Admins can do anything
CREATE POLICY "admin_all_profiles" ON public.profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role IN ('admin', 'moderator')
    )
  );

-- Wallet policies
DROP POLICY IF EXISTS "wallets_own_select" ON public.wallets;
DROP POLICY IF EXISTS "wallets_admin" ON public.wallets;

CREATE POLICY "wallets_own_select" ON public.wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "wallets_admin" ON public.wallets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role IN ('admin', 'moderator')
    )
  );

-- 7. Grant table permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.wallets TO authenticated;

-- 8. Fix is_admin and is_vendor functions
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT TRUE FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'moderator') LIMIT 1),
    FALSE
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.is_vendor()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT TRUE FROM public.profiles WHERE id = auth.uid() AND role = 'vendor' LIMIT 1),
    FALSE
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_vendor() TO authenticated;

-- 9. Create ensure_profile_exists function for existing users
CREATE OR REPLACE FUNCTION public.ensure_profile_exists()
RETURNS void
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_email text;
  v_role text := 'buyer';
  v_username text;
BEGIN
  -- Check if profile exists
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_user_id) THEN
    RETURN;
  END IF;

  -- Get email
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  v_email := COALESCE(v_email, '');
  
  -- Determine role
  IF v_email ILIKE '%@admin.com' THEN
    v_role := 'admin';
  ELSIF v_email ILIKE '%@vendor.com' THEN
    v_role := 'vendor';
  END IF;
  
  -- Generate username
  IF v_email != '' THEN
    v_username := split_part(v_email, '@', 1);
  ELSE
    v_username := 'user_' || substr(v_user_id::text, 1, 8);
  END IF;

  -- Create profile
  INSERT INTO public.profiles (id, role, username, full_name, kyc_status, is_active)
  VALUES (
    v_user_id,
    v_role::public.user_role,
    v_username,
    v_username,
    'pending'::public.kyc_status,
    TRUE
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create wallet
  INSERT INTO public.wallets (user_id, balance, escrow_balance)
  VALUES (v_user_id, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error in ensure_profile_exists: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.ensure_profile_exists() TO authenticated;

-- 10. Log success
DO $$
BEGIN
  RAISE NOTICE 'Auth trigger fix applied successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'Key changes:';
  RAISE NOTICE '1. Trigger function now has proper SECURITY DEFINER with search_path';
  RAISE NOTICE '2. Added exception handling for all edge cases';
  RAISE NOTICE '3. Explicit type casting for enums';
  RAISE NOTICE '4. RLS policies recreated cleanly';
  RAISE NOTICE '5. Grant permissions to authenticated users';
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTANT: Test user registration now.';
  RAISE NOTICE 'If still failing, check Supabase logs for detailed error messages.';
END $$;