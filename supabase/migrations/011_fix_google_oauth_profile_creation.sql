-- ============================================================
-- AUTOX MARKETPLACE - FIX GOOGLE OAUTH PROFILE CREATION
-- Ensures profiles and wallets are created for Google OAuth users
-- ============================================================

-- First, let's check if the trigger is working by creating a debug version
-- that logs to a table

-- Create a debug log table (if not exists)
CREATE TABLE IF NOT EXISTS public.auth_debug_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  user_id UUID,
  email TEXT,
  details JSONB,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grant permissions
GRANT ALL ON public.auth_debug_log TO authenticated;
GRANT ALL ON public.auth_debug_log TO postgres;
ALTER TABLE public.auth_debug_log ENABLE ROW LEVEL SECURITY;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user_signup();

-- Create a new robust trigger function
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text := 'buyer';
  v_username text;
  v_full_name text;
  v_email text;
  v_profile_exists boolean;
  v_wallet_exists boolean;
BEGIN
  -- Log the trigger invocation
  INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
  VALUES ('trigger_started', NEW.id, NEW.email, jsonb_build_object(
    'provider', NEW.email_confirmed_at,
    'raw_metadata', NEW.raw_user_meta_data
  ));

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
    -- Remove special characters and make it URL-safe
    v_username := regexp_replace(v_username, '[^a-zA-Z0-9._-]', '', 'g');
    -- Ensure it's not empty after cleaning
    IF v_username = '' OR v_username IS NULL THEN
      v_username := 'user_' || substr(NEW.id::text, 1, 8);
    END IF;
  ELSE
    v_username := 'user_' || substr(NEW.id::text, 1, 8);
  END IF;
  
  -- Get full name from metadata or use username
  v_full_name := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', ''),
    NULLIF(NEW.raw_user_meta_data->>'given_name', ''),
    v_username
  );

  -- Check if profile already exists
  SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = NEW.id) INTO v_profile_exists;
  
  IF NOT v_profile_exists THEN
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
      
      INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
      VALUES ('profile_created', NEW.id, v_email, jsonb_build_object(
        'role', v_role,
        'username', v_username,
        'full_name', v_full_name
      ));
    EXCEPTION 
      WHEN unique_violation THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('profile_unique_violation', NEW.id, v_email, NULL, SQLERRM);
        
        -- Update existing profile
        UPDATE public.profiles 
        SET 
          role = v_role::public.user_role,
          username = v_username,
          full_name = v_full_name,
          avatar_url = NULLIF(NEW.raw_user_meta_data->>'avatar_url', ''),
          updated_at = NOW()
        WHERE id = NEW.id;
      WHEN foreign_key_violation THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('profile_fk_violation', NEW.id, v_email, NULL, SQLERRM);
      WHEN OTHERS THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('profile_other_error', NEW.id, v_email, NULL, SQLERRM);
        RAISE; -- Re-raise the exception to fail the signup
    END;
  ELSE
    INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
    VALUES ('profile_already_exists', NEW.id, v_email, NULL);
  END IF;

  -- Check if wallet already exists
  SELECT EXISTS(SELECT 1 FROM public.wallets WHERE user_id = NEW.id) INTO v_wallet_exists;

  -- Create wallet with error handling
  IF NOT v_wallet_exists THEN
    BEGIN
      INSERT INTO public.wallets (user_id, balance, escrow_balance, created_at, updated_at)
      VALUES (NEW.id, 0, 0, NOW(), NOW());
      
      INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
      VALUES ('wallet_created', NEW.id, v_email, NULL);
    EXCEPTION 
      WHEN unique_violation THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('wallet_unique_violation', NEW.id, v_email, NULL, SQLERRM);
      WHEN foreign_key_violation THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('wallet_fk_violation', NEW.id, v_email, NULL, SQLERRM);
      WHEN OTHERS THEN
        INSERT INTO public.auth_debug_log (event_type, user_id, email, details, error_message)
        VALUES ('wallet_other_error', NEW.id, v_email, NULL, SQLERRM);
        RAISE; -- Re-raise the exception
    END;
  ELSE
    INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
    VALUES ('wallet_already_exists', NEW.id, v_email, NULL);
  END IF;

  -- Log success
  INSERT INTO public.auth_debug_log (event_type, user_id, email, details)
  VALUES ('trigger_completed', NEW.id, v_email, NULL);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION handle_new_user_signup() TO postgres;
GRANT EXECUTE ON FUNCTION handle_new_user_signup() TO service_role;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- ============================================================
-- FIX RLS POLICIES
-- ============================================================

-- Ensure profiles table has correct RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "profiles_select_public" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_on_signup" ON public.profiles;
DROP POLICY IF EXISTS "admin_all_profiles" ON public.profiles;

-- Recreate policies
CREATE POLICY "profiles_select_public" ON public.profiles FOR SELECT
  USING (TRUE);

CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Critical: Allow the trigger to insert profiles
-- This policy allows authenticated users to insert their own profile
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

-- Grant table permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.wallets TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.wallets TO service_role;

-- ============================================================
-- CREATE ADMIN HELPER FUNCTIONS
-- ============================================================

-- Function to manually create profile for existing users
CREATE OR REPLACE FUNCTION public.create_missing_profiles()
RETURNS void
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  v_role text := 'buyer';
  v_username text;
  v_full_name text;
  v_email text;
BEGIN
  FOR r IN 
    SELECT au.id, au.email, au.raw_user_meta_data
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.id IS NULL
  LOOP
    v_email := COALESCE(r.email, '');
    
    IF v_email ILIKE '%@admin.com' THEN
      v_role := 'admin';
    ELSIF v_email ILIKE '%@vendor.com' THEN
      v_role := 'vendor';
    ELSE
      v_role := 'buyer';
    END IF;
    
    IF v_email != '' THEN
      v_username := split_part(v_email, '@', 1);
      v_username := regexp_replace(v_username, '[^a-zA-Z0-9._-]', '', 'g');
      IF v_username = '' OR v_username IS NULL THEN
        v_username := 'user_' || substr(r.id::text, 1, 8);
      END IF;
    ELSE
      v_username := 'user_' || substr(r.id::text, 1, 8);
    END IF;
    
    v_full_name := COALESCE(
      NULLIF(r.raw_user_meta_data->>'full_name', ''),
      NULLIF(r.raw_user_meta_data->>'name', ''),
      NULLIF(r.raw_user_meta_data->>'given_name', ''),
      v_username
    );
    
    -- Insert profile
    INSERT INTO public.profiles (id, role, username, full_name, avatar_url, kyc_status, is_active)
    VALUES (
      r.id,
      v_role::public.user_role,
      v_username,
      v_full_name,
      NULLIF(r.raw_user_meta_data->>'avatar_url', ''),
      'pending'::public.kyc_status,
      TRUE
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Insert wallet
    INSERT INTO public.wallets (user_id, balance, escrow_balance)
    VALUES (r.id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.create_missing_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_missing_profiles() TO service_role;

-- ============================================================
-- RUN THE FIX FOR EXISTING USERS
-- ============================================================

-- This will create profiles and wallets for all users who signed up but don't have them
SELECT public.create_missing_profiles();

-- ============================================================
-- LOG SUCCESS
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'AUTH TRIGGER FIX APPLIED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '1. Added debug logging to track trigger execution';
  RAISE NOTICE '2. Improved username generation with special char removal';
  RAISE NOTICE '3. Fixed RLS policies for profile insertion';
  RAISE NOTICE '4. Created function to fix existing users';
  RAISE NOTICE '5. Executed fix for all existing users without profiles';
  RAISE NOTICE '';
  RAISE NOTICE 'To verify the fix:';
  RAISE NOTICE '- Check public.auth_debug_log table for trigger execution';
  RAISE NOTICE '- Check public.profiles table for new profiles';
  RAISE NOTICE '- Check public.wallets table for new wallets';
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTANT: Make sure Google OAuth is enabled in Supabase!';
  RAISE NOTICE 'Go to: Authentication -> Providers -> Google -> Enable';
  RAISE NOTICE '';
END $$;