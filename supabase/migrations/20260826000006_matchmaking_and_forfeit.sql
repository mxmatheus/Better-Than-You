-- BETTER THAN YOU — Matchmaking Queue & Forfeit Grace Period
-- Migration: 20260826000006_matchmaking_and_forfeit.sql
-- Status: Canonical Baseline

-- 1. MATCHMAKING QUEUE TABLE
CREATE TABLE IF NOT EXISTS public.matchmaking_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    mmr INTEGER NOT NULL CHECK (mmr >= 0),
    enqueued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.matchmaking_queue ENABLE ROW LEVEL SECURITY;

-- Players can read queue entries and manage their own entry
CREATE POLICY "Users can view queue"
    ON public.matchmaking_queue
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can insert own queue entry"
    ON public.matchmaking_queue
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can delete own queue entry"
    ON public.matchmaking_queue
    FOR DELETE
    TO authenticated
    USING (auth.uid() = player_id);

-- 2. DISCONNECT / FORFEIT METADATA ON MATCHES
ALTER TABLE public.matches
ADD COLUMN IF NOT EXISTS player_a_heartbeat TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS player_b_heartbeat TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS forfeit_winner_id UUID REFERENCES public.profiles(id);

-- 3. MATCHMAKING RPC: FIND OR CREATE MATCH
CREATE OR REPLACE FUNCTION public.find_or_create_match()
RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    v_prof_a RECORD;
    v_opponent RECORD;
    v_match_id UUID;
    v_match_seed BIGINT;
    v_prng_state BIGINT;
    v_round_seed BIGINT;
    v_sched challenge_type[] := ARRAY[
        'REACTION'::challenge_type,
        'PRECISION'::challenge_type,
        'MEMORY'::challenge_type,
        'REACTION'::challenge_type,
        'PRECISION'::challenge_type,
        'MEMORY'::challenge_type,
        'REACTION'::challenge_type
    ];
    v_existing_match RECORD;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Fetch caller profile
    SELECT * INTO v_prof_a FROM public.profiles WHERE id = v_uid;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found for %', v_uid;
    END IF;

    -- Check if user is already in an active match
    SELECT * INTO v_existing_match FROM public.matches
    WHERE (player_a_id = v_uid OR player_b_id = v_uid)
      AND status NOT IN ('SETTLED', 'ABANDONED')
    ORDER BY created_at DESC LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'status', 'MATCH_ACTIVE',
            'match_id', v_existing_match.id,
            'player_a_id', v_existing_match.player_a_id,
            'player_b_id', v_existing_match.player_b_id,
            'match_seed', v_existing_match.match_seed,
            'current_round_index', v_existing_match.current_round_index,
            'match_status', v_existing_match.status
        );
    END IF;

    -- Clean stale queue entries (>60s)
    DELETE FROM public.matchmaking_queue WHERE enqueued_at < NOW() - INTERVAL '60 seconds';

    -- Find waiting opponent with row lock (skipping locked rows to prevent concurrent race conditions)
    SELECT * INTO v_opponent
    FROM public.matchmaking_queue
    WHERE player_id <> v_uid
    ORDER BY enqueued_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF FOUND THEN
        -- Remove opponent from queue
        DELETE FROM public.matchmaking_queue WHERE id = v_opponent.id;
        DELETE FROM public.matchmaking_queue WHERE player_id = v_uid;

        -- Generate server-side 32-bit match seed
        v_match_seed := ((EXTRACT(EPOCH FROM NOW())::BIGINT * 1000) + FLOOR(RANDOM() * 1000)::BIGINT) & 4294967295;

        -- Insert Match record
        INSERT INTO public.matches (
            player_a_id,
            player_b_id,
            status,
            match_seed,
            scheduled_challenges,
            total_rounds,
            target_wins,
            current_round_index,
            player_a_mmr_start,
            player_b_mmr_start
        ) VALUES (
            v_opponent.player_id, -- Player A (queued first)
            v_uid,                -- Player B
            'ROUND_PREPARING',
            v_match_seed,
            v_sched,
            7,
            4,
            1,
            v_opponent.mmr,
            v_prof_a.mmr
        ) RETURNING id INTO v_match_id;

        -- Generate 7 deterministically seeded rounds
        v_prng_state := v_match_seed;
        FOR i IN 1..7 LOOP
            SELECT state, next_u32 INTO v_prng_state, v_round_seed FROM public.mulberry32_step(v_prng_state);
            
            INSERT INTO public.match_rounds (
                match_id,
                round_index,
                challenge_type,
                round_seed,
                status
            ) VALUES (
                v_match_id,
                i,
                v_sched[i],
                v_round_seed,
                CASE WHEN i = 1 THEN 'ROUND_PREPARING'::public.match_lifecycle_state ELSE 'ROUND_PREPARING'::public.match_lifecycle_state END
            );
        END LOOP;

        RETURN jsonb_build_object(
            'status', 'MATCH_CREATED',
            'match_id', v_match_id,
            'player_a_id', v_opponent.player_id,
            'player_b_id', v_uid,
            'match_seed', v_match_seed,
            'current_round_index', 1,
            'match_status', 'ROUND_PREPARING'
        );
    ELSE
        -- No opponent available: insert or update queue entry
        INSERT INTO public.matchmaking_queue (player_id, mmr, enqueued_at)
        VALUES (v_uid, v_prof_a.mmr, NOW())
        ON CONFLICT (player_id) DO UPDATE
        SET mmr = EXCLUDED.mmr, enqueued_at = NOW();

        RETURN jsonb_build_object(
            'status', 'QUEUED',
            'player_id', v_uid
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute to authenticated users
REVOKE EXECUTE ON FUNCTION public.find_or_create_match() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.find_or_create_match() TO authenticated;

-- 4. CANCEL MATCHMAKING RPC
CREATE OR REPLACE FUNCTION public.cancel_matchmaking()
RETURNS VOID AS $$
BEGIN
    DELETE FROM public.matchmaking_queue WHERE player_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.cancel_matchmaking() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.cancel_matchmaking() TO authenticated;

-- 5. FORFEIT / DISCONNECT RPC (20-second grace enforcement)
CREATE OR REPLACE FUNCTION public.forfeit_match(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
    v_uid UUID;
    m RECORD;
    v_winner UUID;
BEGIN
    v_uid := auth.uid();
    SELECT * INTO m FROM public.matches WHERE id = p_match_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match % not found', p_match_id;
    END IF;

    IF m.status = 'SETTLED' THEN
        RETURN;
    END IF;

    IF v_uid <> m.player_a_id AND v_uid <> m.player_b_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Opponent wins by forfeit
    IF v_uid = m.player_a_id THEN
        v_winner := m.player_b_id;
        UPDATE public.matches SET player_b_score = m.target_wins WHERE id = p_match_id;
    ELSE
        v_winner := m.player_a_id;
        UPDATE public.matches SET player_a_score = m.target_wins WHERE id = p_match_id;
    END IF;

    UPDATE public.matches
    SET forfeit_winner_id = v_winner
    WHERE id = p_match_id;

    -- Perform authoritative Elo settlement
    PERFORM public.settle_match_internal(p_match_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.forfeit_match(UUID) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.forfeit_match(UUID) TO authenticated;
