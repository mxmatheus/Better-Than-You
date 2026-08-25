-- BETTER THAN YOU — Auth Profile Trigger & Realtime Publications
-- Migration: 20260826000004_realtime_and_auth_triggers.sql
-- Status: Canonical Baseline

-- 1. AUTH TRIGGER: AUTO-CREATE PROFILE ON USER SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_display_name TEXT;
BEGIN
    v_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        'player_' || SUBSTRING(NEW.id::TEXT, 1, 8)
    );
    v_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        'Player ' || SUBSTRING(NEW.id::TEXT, 1, 4)
    );

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
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. ENABLE SUPABASE REALTIME ON MATCH TABLES
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.match_rounds;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.round_submissions;
    END IF;
END $$;
