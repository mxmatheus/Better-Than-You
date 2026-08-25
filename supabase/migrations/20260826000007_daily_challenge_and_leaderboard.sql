-- BETTER THAN YOU — Daily Challenge Mode & Global Leaderboard
-- Migration: 20260826000007_daily_challenge_and_leaderboard.sql
-- Status: Canonical Baseline

-- 1. EXTEND DAILY_SUBMISSIONS TABLE FOR IN-PROGRESS ATTEMPTS
ALTER TABLE public.daily_submissions
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'COMPLETED')),
ADD COLUMN IF NOT EXISTS current_round_index INTEGER NOT NULL DEFAULT 1 CHECK (current_round_index >= 1),
ALTER COLUMN completed_at DROP NOT NULL,
ALTER COLUMN completed_at SET DEFAULT NULL;

-- 2. DETERMINISTIC DAILY SEED GENERATION HELPER
CREATE OR REPLACE FUNCTION public.derive_daily_seed(p_date DATE)
RETURNS BIGINT AS $$
DECLARE
    v_date_int BIGINT;
BEGIN
    v_date_int := EXTRACT(YEAR FROM p_date)::BIGINT * 10000 +
                  EXTRACT(MONTH FROM p_date)::BIGINT * 100 +
                  EXTRACT(DAY FROM p_date)::BIGINT;
    RETURN ((v_date_int * 1664525) + 1013904223) & 4294967295;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = public;

-- 3. GET OR CREATE DAILY CHALLENGE (Idempotent & Deterministic)
CREATE OR REPLACE FUNCTION public.get_or_create_daily_challenge(p_date DATE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::DATE)
RETURNS JSONB AS $$
DECLARE
    v_dc RECORD;
    v_seed BIGINT;
    v_prng_state BIGINT;
    v_u BIGINT;
    v_type_idx INT;
    v_types challenge_type[] := ARRAY['REACTION'::challenge_type, 'PRECISION'::challenge_type, 'MEMORY'::challenge_type];
    v_sched challenge_type[] := '{}';
BEGIN
    SELECT * INTO v_dc FROM public.daily_challenges WHERE challenge_date = p_date;

    IF NOT FOUND THEN
        v_seed := public.derive_daily_seed(p_date);
        v_prng_state := v_seed;

        -- Generate 10 deterministic challenge types
        FOR i IN 1..10 LOOP
            SELECT state, next_u32 INTO v_prng_state, v_u FROM public.mulberry32_step(v_prng_state);
            v_type_idx := (v_u % 3) + 1;
            v_sched := array_append(v_sched, v_types[v_type_idx]);
        END LOOP;

        INSERT INTO public.daily_challenges (
            challenge_date,
            seed,
            scheduled_challenges,
            total_rounds
        ) VALUES (
            p_date,
            v_seed,
            v_sched,
            10
        )
        ON CONFLICT (challenge_date) DO NOTHING;

        SELECT * INTO v_dc FROM public.daily_challenges WHERE challenge_date = p_date;
    END IF;

    RETURN jsonb_build_object(
        'challenge_date', v_dc.challenge_date,
        'seed', v_dc.seed,
        'scheduled_challenges', v_dc.scheduled_challenges,
        'total_rounds', v_dc.total_rounds
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.get_or_create_daily_challenge(DATE) FROM public;
GRANT EXECUTE ON FUNCTION public.get_or_create_daily_challenge(DATE) TO anon, authenticated;

-- 4. START OR RESUME DAILY CHALLENGE (One Attempt Enforcement)
CREATE OR REPLACE FUNCTION public.start_or_resume_daily_challenge(p_date DATE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::DATE)
RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    v_dc_json JSONB;
    v_sub RECORD;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Ensure challenge is initialized
    v_dc_json := public.get_or_create_daily_challenge(p_date);

    -- Fetch or lock submission
    SELECT * INTO v_sub
    FROM public.daily_submissions
    WHERE challenge_date = p_date AND user_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Insert new in-progress attempt
        INSERT INTO public.daily_submissions (
            challenge_date,
            user_id,
            status,
            current_round_index,
            total_score,
            round_scores,
            raw_evidence
        ) VALUES (
            p_date,
            v_uid,
            'IN_PROGRESS',
            1,
            0,
            '{}',
            '[]'::jsonb
        ) RETURNING * INTO v_sub;
    END IF;

    RETURN jsonb_build_object(
        'challenge_date', p_date,
        'seed', (v_dc_json->>'seed')::BIGINT,
        'scheduled_challenges', v_dc_json->'scheduled_challenges',
        'total_rounds', (v_dc_json->>'total_rounds')::INT,
        'status', v_sub.status,
        'current_round_index', v_sub.current_round_index,
        'total_score', v_sub.total_score,
        'round_scores', v_sub.round_scores,
        'completed_at', v_sub.completed_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.start_or_resume_daily_challenge(DATE) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.start_or_resume_daily_challenge(DATE) TO authenticated;

-- 5. SUBMIT DAILY ROUND EVIDENCE (Authoritative Recalculation)
CREATE OR REPLACE FUNCTION public.submit_daily_round_evidence(
    p_date DATE,
    p_round_index INT,
    p_evidence JSONB,
    p_client_version TEXT DEFAULT '1.0.0'
)
RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    v_dc RECORD;
    v_sub RECORD;
    v_ch_type public.challenge_type;
    v_prng_state BIGINT;
    v_u BIGINT;
    v_round_seed BIGINT;
    v_score INT;
    v_val_status public.validation_status;
    v_metric TEXT;
    v_raw NUMERIC;
    v_u1 BIGINT;
    v_u2 BIGINT;
    v_target_x NUMERIC;
    v_target_y NUMERIC;
    v_new_scores INT[];
    v_new_evidence JSONB;
    v_is_last_round BOOLEAN;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_dc FROM public.daily_challenges WHERE challenge_date = p_date;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Daily challenge % not found', p_date;
    END IF;

    SELECT * INTO v_sub FROM public.daily_submissions
    WHERE challenge_date = p_date AND user_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No daily attempt started for date %', p_date;
    END IF;

    IF v_sub.status = 'COMPLETED' THEN
        RAISE EXCEPTION 'Daily challenge is already completed and immutable';
    END IF;

    IF v_sub.current_round_index <> p_round_index THEN
        RAISE EXCEPTION 'Round index mismatch. Expected %, got %', v_sub.current_round_index, p_round_index;
    END IF;

    v_ch_type := v_dc.scheduled_challenges[p_round_index];

    -- Derive round seed from daily seed
    v_prng_state := v_dc.seed;
    FOR i IN 1..p_round_index LOOP
        SELECT state, next_u32 INTO v_prng_state, v_round_seed FROM public.mulberry32_step(v_prng_state);
    END LOOP;

    -- Authoritative scoring
    CASE v_ch_type
        WHEN 'REACTION' THEN
            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_reaction(v_round_seed, p_evidence);

        WHEN 'MEMORY' THEN
            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_memory(6, p_evidence); -- Daily mode uses length 6

        WHEN 'PRECISION' THEN
            v_prng_state := v_round_seed;
            SELECT state, next_u32 INTO v_prng_state, v_u1 FROM public.mulberry32_step(v_prng_state);
            SELECT state, next_u32 INTO v_prng_state, v_u2 FROM public.mulberry32_step(v_prng_state);
            v_target_x := 0.18 + (v_u1::NUMERIC / 4294967296.0) * 0.64;
            v_target_y := 0.18 + (v_u2::NUMERIC / 4294967296.0) * 0.64;

            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_precision(v_target_x, v_target_y, 0.12, p_evidence);
    END CASE;

    v_new_scores := array_append(v_sub.round_scores, v_score);
    v_new_evidence := v_sub.raw_evidence || jsonb_build_array(jsonb_build_object(
        'round_index', p_round_index,
        'challenge_type', v_ch_type,
        'round_seed', v_round_seed,
        'score', v_score,
        'metric', v_metric,
        'evidence', p_evidence
    ));

    v_is_last_round := (p_round_index >= v_dc.total_rounds);

    IF v_is_last_round THEN
        UPDATE public.daily_submissions
        SET status = 'COMPLETED',
            total_score = total_score + v_score,
            round_scores = v_new_scores,
            raw_evidence = v_new_evidence,
            completed_at = NOW()
        WHERE id = v_sub.id;
    ELSE
        UPDATE public.daily_submissions
        SET current_round_index = current_round_index + 1,
            total_score = total_score + v_score,
            round_scores = v_new_scores,
            raw_evidence = v_new_evidence
        WHERE id = v_sub.id;
    END IF;

    RETURN jsonb_build_object(
        'round_index', p_round_index,
        'challenge_type', v_ch_type,
        'authoritative_score', v_score,
        'formatted_metric', v_metric,
        'validation_status', v_val_status,
        'running_total_score', v_sub.total_score + v_score,
        'is_completed', v_is_last_round
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.submit_daily_round_evidence(DATE, INT, JSONB, TEXT) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.submit_daily_round_evidence(DATE, INT, JSONB, TEXT) TO authenticated;

-- 6. GLOBAL LEADERBOARD & USER RANK RPCs
CREATE OR REPLACE FUNCTION public.get_daily_leaderboard(
    p_date DATE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::DATE,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    rank BIGINT,
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    total_score INT,
    completed_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY s.total_score DESC, s.completed_at ASC, s.user_id ASC) AS rank,
        s.user_id,
        p.username,
        p.display_name,
        p.avatar_url,
        s.total_score,
        s.completed_at
    FROM public.daily_submissions s
    JOIN public.profiles p ON p.id = s.user_id
    WHERE s.challenge_date = p_date AND s.status = 'COMPLETED'
    ORDER BY s.total_score DESC, s.completed_at ASC, s.user_id ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.get_daily_leaderboard(DATE, INT) FROM public;
GRANT EXECUTE ON FUNCTION public.get_daily_leaderboard(DATE, INT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_daily_user_rank(
    p_date DATE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::DATE
)
RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    v_my_sub RECORD;
    v_total_completed BIGINT;
    v_rank BIGINT;
    v_percentile NUMERIC;
    v_nearby JSONB;
    v_next_utc_midnight TIMESTAMPTZ;
    v_ms_until_rollover BIGINT;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_my_sub
    FROM public.daily_submissions
    WHERE challenge_date = p_date AND user_id = v_uid AND status = 'COMPLETED';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'has_completed', FALSE,
            'challenge_date', p_date
        );
    END IF;

    SELECT COUNT(*) INTO v_total_completed
    FROM public.daily_submissions
    WHERE challenge_date = p_date AND status = 'COMPLETED';

    -- Deterministic rank with tie-breaker (score DESC, completed_at ASC, user_id ASC)
    SELECT COUNT(*) + 1 INTO v_rank
    FROM public.daily_submissions s
    WHERE s.challenge_date = p_date AND s.status = 'COMPLETED'
      AND (
          s.total_score > v_my_sub.total_score
          OR (s.total_score = v_my_sub.total_score AND s.completed_at < v_my_sub.completed_at)
          OR (s.total_score = v_my_sub.total_score AND s.completed_at = v_my_sub.completed_at AND s.user_id < v_my_sub.user_id)
      );

    v_percentile := CASE 
        WHEN v_total_completed > 0 THEN ROUND(((v_rank::NUMERIC / v_total_completed::NUMERIC) * 100.0), 1)
        ELSE 100.0
    END;

    -- Fetch +/-3 nearby players
    WITH ranked_entries AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY s.total_score DESC, s.completed_at ASC, s.user_id ASC) AS entry_rank,
            s.user_id AS entry_user_id,
            p.username,
            p.display_name,
            s.total_score,
            (s.user_id = v_uid) AS is_current_user
        FROM public.daily_submissions s
        JOIN public.profiles p ON p.id = s.user_id
        WHERE s.challenge_date = p_date AND s.status = 'COMPLETED'
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'rank', entry_rank,
            'user_id', entry_user_id,
            'username', username,
            'display_name', display_name,
            'total_score', total_score,
            'is_current_user', is_current_user
        ) ORDER BY entry_rank ASC
    ) INTO v_nearby
    FROM ranked_entries
    WHERE entry_rank BETWEEN GREATEST(1, v_rank - 3) AND (v_rank + 3);

    -- Compute countdown to next 00:00 UTC
    v_next_utc_midnight := ((p_date + INTERVAL '1 day')::TIMESTAMP AT TIME ZONE 'UTC');
    v_ms_until_rollover := GREATEST(0, (EXTRACT(EPOCH FROM (v_next_utc_midnight - NOW())) * 1000)::BIGINT);

    RETURN jsonb_build_object(
        'has_completed', TRUE,
        'challenge_date', p_date,
        'today_score', v_my_sub.total_score,
        'global_rank', v_rank,
        'total_participants', v_total_completed,
        'percentile', v_percentile,
        'nearby_players', COALESCE(v_nearby, '[]'::jsonb),
        'ms_until_next_challenge', v_ms_until_rollover
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.get_daily_user_rank(DATE) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_daily_user_rank(DATE) TO authenticated;
