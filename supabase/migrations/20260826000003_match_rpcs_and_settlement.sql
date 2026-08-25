-- BETTER THAN YOU — Authoritative Match RPCs, Concurrency Locks & Elo Settlement
-- Migration: 20260826000003_match_rpcs_and_settlement.sql
-- Status: Canonical Baseline

-- 1. ELO MMR SETTLEMENT HELPER (Internal & Transaction-Safe)
CREATE OR REPLACE FUNCTION public.settle_match_internal(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
    m RECORD;
    prof_a RECORD;
    prof_b RECORD;
    k_a NUMERIC;
    k_b NUMERIC;
    e_a NUMERIC;
    e_b NUMERIC;
    s_a NUMERIC;
    s_b NUMERIC;
    delta_a INT;
    delta_b INT;
    winner_uuid UUID;
BEGIN
    -- 1. Row lock on match
    SELECT * INTO m FROM public.matches WHERE id = p_match_id FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match % not found', p_match_id;
    END IF;

    -- Idempotency check
    IF m.status = 'SETTLED' THEN
        RETURN;
    END IF;

    -- Fetch and lock player profiles
    SELECT * INTO prof_a FROM public.profiles WHERE id = m.player_a_id FOR UPDATE;
    SELECT * INTO prof_b FROM public.profiles WHERE id = m.player_b_id FOR UPDATE;

    -- Determine outcome scores
    IF m.player_a_score > m.player_b_score THEN
        s_a := 1.0;
        s_b := 0.0;
        winner_uuid := m.player_a_id;
    ELSIF m.player_b_score > m.player_a_score THEN
        s_a := 0.0;
        s_b := 1.0;
        winner_uuid := m.player_b_id;
    ELSE
        s_a := 0.5;
        s_b := 0.5;
        winner_uuid := NULL;
    END IF;

    -- Determine K-factors
    -- Provisional (<10 matches remaining): K=50, High MMR (>=1800): K=20, Standard: K=32
    IF prof_a.provisional_matches_remaining > 0 THEN
        k_a := 50.0;
    ELSIF prof_a.mmr >= 1800 THEN
        k_a := 20.0;
    ELSE
        k_a := 32.0;
    END IF;

    IF prof_b.provisional_matches_remaining > 0 THEN
        k_b := 50.0;
    ELSIF prof_b.mmr >= 1800 THEN
        k_b := 20.0;
    ELSE
        k_b := 32.0;
    END IF;

    -- Calculate expected scores: EA = 1 / (1 + 10^((RB - RA)/400))
    e_a := 1.0 / (1.0 + POWER(10.0, ((prof_b.mmr - prof_a.mmr)::NUMERIC / 400.0)));
    e_b := 1.0 - e_a;

    -- Rating deltas: round(K * (S - E))
    delta_a := ROUND(k_a * (s_a - e_a))::INT;
    delta_b := ROUND(k_b * (s_b - e_b))::INT;

    -- Minimum delta guarantee on decisive win
    IF s_a = 1.0 AND delta_a = 0 THEN delta_a := 1; delta_b := -1; END IF;
    IF s_b = 1.0 AND delta_b = 0 THEN delta_b := 1; delta_a := -1; END IF;

    -- Update player A profile
    UPDATE public.profiles
    SET mmr = GREATEST(0, mmr + delta_a),
        matches_played = matches_played + 1,
        wins = wins + (CASE WHEN s_a = 1.0 THEN 1 ELSE 0 END),
        losses = losses + (CASE WHEN s_a = 0.0 THEN 1 ELSE 0 END),
        draws = draws + (CASE WHEN s_a = 0.5 THEN 1 ELSE 0 END),
        provisional_matches_remaining = GREATEST(0, provisional_matches_remaining - 1),
        rank_tier = (CASE
            WHEN mmr + delta_a >= 2400 THEN 'GRANDMASTER'::public.rank_tier
            WHEN mmr + delta_a >= 2000 THEN 'MASTER'::public.rank_tier
            WHEN mmr + delta_a >= 1700 THEN 'DIAMOND'::public.rank_tier
            WHEN mmr + delta_a >= 1400 THEN 'PLATINUM'::public.rank_tier
            WHEN mmr + delta_a >= 1150 THEN 'GOLD'::public.rank_tier
            WHEN mmr + delta_a >= 900 THEN 'SILVER'::public.rank_tier
            ELSE 'BRONZE'::public.rank_tier
        END),
        updated_at = NOW()
    WHERE id = m.player_a_id;

    -- Update player B profile
    UPDATE public.profiles
    SET mmr = GREATEST(0, mmr + delta_b),
        matches_played = matches_played + 1,
        wins = wins + (CASE WHEN s_b = 1.0 THEN 1 ELSE 0 END),
        losses = losses + (CASE WHEN s_b = 0.0 THEN 1 ELSE 0 END),
        draws = draws + (CASE WHEN s_b = 0.5 THEN 1 ELSE 0 END),
        provisional_matches_remaining = GREATEST(0, provisional_matches_remaining - 1),
        rank_tier = (CASE
            WHEN mmr + delta_b >= 2400 THEN 'GRANDMASTER'::public.rank_tier
            WHEN mmr + delta_b >= 2000 THEN 'MASTER'::public.rank_tier
            WHEN mmr + delta_b >= 1700 THEN 'DIAMOND'::public.rank_tier
            WHEN mmr + delta_b >= 1400 THEN 'PLATINUM'::public.rank_tier
            WHEN mmr + delta_b >= 1150 THEN 'GOLD'::public.rank_tier
            WHEN mmr + delta_b >= 900 THEN 'SILVER'::public.rank_tier
            ELSE 'BRONZE'::public.rank_tier
        END),
        updated_at = NOW()
    WHERE id = m.player_b_id;

    -- Finalize match record
    UPDATE public.matches
    SET status = 'SETTLED',
        winner_id = winner_uuid,
        player_a_mmr_delta = delta_a,
        player_b_mmr_delta = delta_b,
        settled_at = NOW(),
        updated_at = NOW()
    WHERE id = p_match_id;

    -- Audit log
    INSERT INTO public.audit_logs (event_type, resource_id, details)
    VALUES (
        'MATCH_SETTLED',
        p_match_id,
        jsonb_build_object(
            'winner_id', winner_uuid,
            'player_a_score', m.player_a_score,
            'player_b_score', m.player_b_score,
            'delta_a', delta_a,
            'delta_b', delta_b
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. ROUND RESOLUTION HELPER (Internal)
CREATE OR REPLACE FUNCTION public.resolve_round_internal(p_round_id UUID)
RETURNS VOID AS $$
DECLARE
    r RECORD;
    m RECORD;
    sub_a RECORD;
    sub_b RECORD;
    round_win_id UUID;
    is_round_draw BOOLEAN := FALSE;
    score_a_inc INT := 0;
    score_b_inc INT := 0;
    is_match_over BOOLEAN := FALSE;
BEGIN
    SELECT * INTO r FROM public.match_rounds WHERE id = p_round_id FOR UPDATE;
    SELECT * INTO m FROM public.matches WHERE id = r.match_id FOR UPDATE;

    SELECT * INTO sub_a FROM public.round_submissions
    WHERE round_id = p_round_id AND player_id = m.player_a_id;

    SELECT * INTO sub_b FROM public.round_submissions
    WHERE round_id = p_round_id AND player_id = m.player_b_id;

    IF sub_a IS NULL OR sub_b IS NULL THEN
        RETURN; -- Waiting for other submission
    END IF;

    -- Compare scores
    IF sub_a.normalized_score > sub_b.normalized_score THEN
        round_win_id := m.player_a_id;
        score_a_inc := 1;
    ELSIF sub_b.normalized_score > sub_a.normalized_score THEN
        round_win_id := m.player_b_id;
        score_b_inc := 1;
    ELSE
        is_round_draw := TRUE;
        round_win_id := NULL;
    END IF;

    -- Update round record
    UPDATE public.match_rounds
    SET status = 'ROUND_RESULT',
        winner_id = round_win_id,
        is_draw = is_round_draw
    WHERE id = p_round_id;

    -- Update match score
    UPDATE public.matches
    SET player_a_score = player_a_score + score_a_inc,
        player_b_score = player_b_score + score_b_inc,
        updated_at = NOW()
    WHERE id = m.id;

    -- Check early termination / match completion
    IF (m.player_a_score + score_a_inc >= m.target_wins) OR
       (m.player_b_score + score_b_inc >= m.target_wins) OR
       (r.round_index >= m.total_rounds) THEN
        PERFORM public.settle_match_internal(m.id);
    ELSE
        UPDATE public.matches
        SET current_round_index = current_round_index + 1,
            status = 'NEXT_ROUND',
            updated_at = NOW()
        WHERE id = m.id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. PUBLIC RPC: SUBMIT ROUND EVIDENCE (Authoritative)
CREATE OR REPLACE FUNCTION public.submit_round_evidence(
    p_round_id UUID,
    p_evidence JSONB,
    p_client_claimed_score INT DEFAULT NULL,
    p_client_version TEXT DEFAULT '1.0.0'
)
RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    r RECORD;
    m RECORD;
    v_score INT;
    v_val_status public.validation_status;
    v_metric TEXT;
    v_raw NUMERIC;
    v_prng_state BIGINT;
    v_u1 BIGINT;
    v_u2 BIGINT;
    v_target_x NUMERIC;
    v_target_y NUMERIC;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Fetch round and match
    SELECT * INTO r FROM public.match_rounds WHERE id = p_round_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Round % not found', p_round_id;
    END IF;

    SELECT * INTO m FROM public.matches WHERE id = r.match_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match % not found', r.match_id;
    END IF;

    -- Authorization check
    IF v_uid <> m.player_a_id AND v_uid <> m.player_b_id THEN
        RAISE EXCEPTION 'Unauthorized: Caller is not a participant in this match';
    END IF;

    -- Authoritative score recalculation from raw evidence
    CASE r.challenge_type
        WHEN 'REACTION' THEN
            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_reaction(r.round_seed, p_evidence);

        WHEN 'MEMORY' THEN
            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_memory(5, p_evidence);

        WHEN 'PRECISION' THEN
            -- Derive deterministic target position from round seed using Mulberry32
            v_prng_state := r.round_seed;
            SELECT state, next_u32 INTO v_prng_state, v_u1 FROM public.mulberry32_step(v_prng_state);
            SELECT state, next_u32 INTO v_prng_state, v_u2 FROM public.mulberry32_step(v_prng_state);
            v_target_x := 0.18 + (v_u1::NUMERIC / 4294967296.0) * 0.64;
            v_target_y := 0.18 + (v_u2::NUMERIC / 4294967296.0) * 0.64;

            SELECT calculated_score, validation_res, metric_text, raw_val
            INTO v_score, v_val_status, v_metric, v_raw
            FROM public.score_precision(v_target_x, v_target_y, 0.12, p_evidence);
    END CASE;

    -- Insert submission (enforcing UNIQUE(round_id, player_id))
    INSERT INTO public.round_submissions (
        round_id,
        match_id,
        player_id,
        client_claimed_score,
        normalized_score,
        raw_metric,
        formatted_metric,
        validation_status,
        raw_evidence,
        client_version
    ) VALUES (
        p_round_id,
        m.id,
        v_uid,
        p_client_claimed_score,
        v_score,
        v_raw,
        v_metric,
        v_val_status,
        p_evidence,
        p_client_version
    );

    -- Check if both players have submitted to resolve round
    PERFORM public.resolve_round_internal(p_round_id);

    RETURN jsonb_build_object(
        'round_id', p_round_id,
        'player_id', v_uid,
        'authoritative_score', v_score,
        'validation_status', v_val_status,
        'formatted_metric', v_metric
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
