-- BETTER THAN YOU — Row Level Security (RLS) Policies
-- Migration: 20260826000001_rls_policies.sql
-- Status: Canonical Baseline

-- 1. ENABLE RLS ON ALL TABLES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.round_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 2. PROFILES POLICIES
-- Anyone authenticated can read user profiles (for matchmaking/match display)
CREATE POLICY "Profiles are viewable by everyone"
    ON public.profiles
    FOR SELECT
    USING (true);

-- Users can update only their own non-competitive profile fields
CREATE POLICY "Users can update own display profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 3. MATCHES POLICIES
-- Players can view matches they participate in
CREATE POLICY "Participants can view their matches"
    ON public.matches
    FOR SELECT
    TO authenticated
    USING (auth.uid() = player_a_id OR auth.uid() = player_b_id);

-- Direct client INSERT / UPDATE / DELETE on matches is strictly forbidden.
-- All match mutations MUST occur through SECURITY DEFINER RPC functions.

-- 4. MATCH_ROUNDS POLICIES
-- Participants can view match rounds
CREATE POLICY "Participants can view their match rounds"
    ON public.match_rounds
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.matches m
            WHERE m.id = match_rounds.match_id
            AND (m.player_a_id = auth.uid() OR m.player_b_id = auth.uid())
        )
    );

-- Direct client INSERT / UPDATE / DELETE on match_rounds is forbidden.

-- 5. ROUND_SUBMISSIONS POLICIES
-- Participants can view submissions for their match rounds
CREATE POLICY "Participants can view round submissions"
    ON public.round_submissions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.matches m
            WHERE m.id = round_submissions.match_id
            AND (m.player_a_id = auth.uid() OR m.player_b_id = auth.uid())
        )
    );

-- Direct client INSERT / UPDATE / DELETE on round_submissions is forbidden.
-- Evidence MUST be submitted via submit_round_evidence() RPC for server recalculation.

-- 6. DAILY_CHALLENGES POLICIES
-- Daily challenges are publicly readable
CREATE POLICY "Daily challenges are viewable by everyone"
    ON public.daily_challenges
    FOR SELECT
    USING (true);

-- 7. DAILY_SUBMISSIONS POLICIES
-- Daily submissions are viewable by everyone (global leaderboard)
CREATE POLICY "Daily submissions are viewable by everyone"
    ON public.daily_submissions
    FOR SELECT
    USING (true);

-- Authenticated users can insert their own daily submission
CREATE POLICY "Users can submit own daily challenge"
    ON public.daily_submissions
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 8. AUDIT_LOGS POLICIES
-- Audit logs are private to server admin / service role
CREATE POLICY "Audit logs are service role only"
    ON public.audit_logs
    FOR ALL
    TO service_role
    USING (true);
