-- BETTER THAN YOU — Auth, Profile Provisioning & OAuth Hardening Migration
-- Migration: 20260826000009_auth_and_oauth_hardening.sql
-- Status: Canonical Baseline

-- 1. HARDEN HANDLE_NEW_USER TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_display_name TEXT;
    v_base_username TEXT;
    v_counter INT := 0;
BEGIN
    -- Extract base username
    v_base_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        NEW.raw_user_meta_data->>'user_name',
        NEW.raw_user_meta_data->>'preferred_username',
        split_part(NEW.email, '@', 1),
        'player'
    );
    
    -- Sanitize base username: keep only alphanumeric and underscores, length 3-15
    v_base_username := regexp_replace(v_base_username, '[^a-zA-Z0-9_]', '', 'g');
    IF length(v_base_username) < 3 THEN
        v_base_username := 'player_' || SUBSTRING(NEW.id::TEXT, 1, 6);
    ELSIF length(v_base_username) > 15 THEN
        v_base_username := SUBSTRING(v_base_username, 1, 15);
    END IF;

    -- Extract display name
    v_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        v_base_username
    );
    IF length(v_display_name) > 30 THEN
        v_display_name := SUBSTRING(v_display_name, 1, 30);
    END IF;

    -- Disambiguate username
    v_username := v_base_username;
    
    IF NEW.raw_user_meta_data ? 'username' THEN
        -- Explicit username provided in registration
        IF EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username AND id <> NEW.id) THEN
            RAISE EXCEPTION 'USERNAME_ALREADY_TAKEN' USING ERRCODE = '23505';
        END IF;
    ELSE
        -- OAuth sign-in without explicit username: auto-disambiguate with random suffix
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username AND id <> NEW.id) LOOP
            v_counter := v_counter + 1;
            v_username := SUBSTRING(v_base_username, 1, 14) || '_' || (floor(random() * 9000 + 1000)::INT);
            IF v_counter > 10 THEN
                v_username := 'player_' || SUBSTRING(NEW.id::TEXT, 1, 8);
                EXIT;
            END IF;
        END LOOP;
    END IF;

    -- Provision or update profile
    INSERT INTO public.profiles (
        id,
        username,
        display_name,
        avatar_url,
        mmr,
        provisional_matches_remaining,
        rank_tier
    ) VALUES (
        NEW.id,
        v_username,
        v_display_name,
        NEW.raw_user_meta_data->>'avatar_url',
        1000,
        10,
        'BRONZE'
    )
    ON CONFLICT (id) DO UPDATE SET
        avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. USERNAME AVAILABILITY CHECK RPC FOR CLIENT UX
CREATE OR REPLACE FUNCTION public.check_username_available(p_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF char_length(p_username) < 3 OR char_length(p_username) > 20 THEN
        RETURN FALSE;
    END IF;

    IF p_username !~ '^[a-zA-Z0-9_]+$' THEN
        RETURN FALSE;
    END IF;

    RETURN NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE LOWER(username) = LOWER(p_username)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO anon, authenticated;
