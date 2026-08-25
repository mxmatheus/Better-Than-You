-- BETTER THAN YOU — Production Schema Migration
-- Migration: 20260826000000_core_schema.sql
-- Status: Canonical Baseline

-- 1. ENUMS
CREATE TYPE match_lifecycle_state AS ENUM (
    'MATCHMAKING',
    'MATCH_FOUND',
    'READY',
    'ROUND_PREPARING',
    'ROUND_ACTIVE',
    'WAITING_FOR_SUBMISSIONS',
    'VALIDATING',
    'ROUND_RESULT',
    'NEXT_ROUND',
    'MATCH_COMPLETED',
    'SETTLING',
    'SETTLED',
    'ABANDONED'
);

CREATE TYPE round_outcome AS ENUM (
    'WIN',
    'LOSS',
    'DRAW'
);

CREATE TYPE challenge_type AS ENUM (
    'REACTION',
    'MEMORY',
    'PRECISION'
);

CREATE TYPE validation_status AS ENUM (
    'VALID',
    'FLAGGED',
    'EARLY_FAULT',
    'TIMEOUT',
    'REJECTED'
);

CREATE TYPE rank_tier AS ENUM (
    'BRONZE',
    'SILVER',
    'GOLD',
    'PLATINUM',
    'DIAMOND',
    'MASTER',
    'GRANDMASTER'
);

-- 2. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
    display_name TEXT NOT NULL CHECK (char_length(display_name) >= 1 AND char_length(display_name) <= 30),
    avatar_url TEXT,
    mmr INTEGER NOT NULL DEFAULT 1000 CHECK (mmr >= 0),
    provisional_matches_remaining INTEGER NOT NULL DEFAULT 10 CHECK (provisional_matches_remaining >= 0),
    matches_played INTEGER NOT NULL DEFAULT 0 CHECK (matches_played >= 0),
    wins INTEGER NOT NULL DEFAULT 0 CHECK (wins >= 0),
    losses INTEGER NOT NULL DEFAULT 0 CHECK (losses >= 0),
    draws INTEGER NOT NULL DEFAULT 0 CHECK (draws >= 0),
    rank_tier rank_tier NOT NULL DEFAULT 'BRONZE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. MATCHES TABLE
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_a_id UUID NOT NULL REFERENCES public.profiles(id),
    player_b_id UUID REFERENCES public.profiles(id),
    status match_lifecycle_state NOT NULL DEFAULT 'MATCHMAKING',
    match_seed BIGINT NOT NULL,
    scheduled_challenges challenge_type[] NOT NULL,
    total_rounds INTEGER NOT NULL DEFAULT 7 CHECK (total_rounds > 0),
    target_wins INTEGER NOT NULL DEFAULT 4 CHECK (target_wins > 0),
    current_round_index INTEGER NOT NULL DEFAULT 1 CHECK (current_round_index >= 1),
    player_a_score INTEGER NOT NULL DEFAULT 0 CHECK (player_a_score >= 0),
    player_b_score INTEGER NOT NULL DEFAULT 0 CHECK (player_b_score >= 0),
    winner_id UUID REFERENCES public.profiles(id),
    player_a_mmr_start INTEGER NOT NULL,
    player_b_mmr_start INTEGER,
    player_a_mmr_delta INTEGER,
    player_b_mmr_delta INTEGER,
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT players_must_differ CHECK (player_b_id IS NULL OR player_a_id <> player_b_id)
);

-- 4. MATCH_ROUNDS TABLE
CREATE TABLE IF NOT EXISTS public.match_rounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    round_index INTEGER NOT NULL CHECK (round_index >= 1),
    challenge_type challenge_type NOT NULL,
    round_seed BIGINT NOT NULL,
    status match_lifecycle_state NOT NULL DEFAULT 'ROUND_PREPARING',
    started_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    winner_id UUID REFERENCES public.profiles(id),
    is_draw BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(match_id, round_index)
);

-- 5. ROUND_SUBMISSIONS TABLE
CREATE TABLE IF NOT EXISTS public.round_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID NOT NULL REFERENCES public.match_rounds(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.profiles(id),
    client_claimed_score INTEGER,
    normalized_score INTEGER NOT NULL CHECK (normalized_score BETWEEN 0 AND 1000),
    raw_metric NUMERIC NOT NULL,
    formatted_metric TEXT NOT NULL,
    validation_status validation_status NOT NULL DEFAULT 'VALID',
    raw_evidence JSONB NOT NULL,
    client_version TEXT NOT NULL DEFAULT '1.0.0',
    latency_ms INTEGER,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(round_id, player_id)
);

-- 6. DAILY_CHALLENGES TABLE
CREATE TABLE IF NOT EXISTS public.daily_challenges (
    challenge_date DATE PRIMARY KEY,
    seed BIGINT NOT NULL,
    scheduled_challenges challenge_type[] NOT NULL,
    total_rounds INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. DAILY_SUBMISSIONS TABLE
CREATE TABLE IF NOT EXISTS public.daily_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_date DATE NOT NULL REFERENCES public.daily_challenges(challenge_date),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    total_score INTEGER NOT NULL CHECK (total_score >= 0),
    round_scores INTEGER[] NOT NULL,
    raw_evidence JSONB NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(challenge_date, user_id)
);

-- 8. AUDIT_LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    actor_id UUID REFERENCES public.profiles(id),
    resource_id UUID,
    details JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_matches_player_a ON public.matches(player_a_id);
CREATE INDEX IF NOT EXISTS idx_matches_player_b ON public.matches(player_b_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_match_rounds_match ON public.match_rounds(match_id, round_index);
CREATE INDEX IF NOT EXISTS idx_round_submissions_round ON public.round_submissions(round_id);
CREATE INDEX IF NOT EXISTS idx_round_submissions_player ON public.round_submissions(player_id);
CREATE INDEX IF NOT EXISTS idx_daily_submissions_leaderboard ON public.daily_submissions(challenge_date, total_score DESC, completed_at ASC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id, event_type);
