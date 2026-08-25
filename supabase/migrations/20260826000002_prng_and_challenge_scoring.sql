-- BETTER THAN YOU — Server PRNG & Authoritative Scoring Functions
-- Migration: 20260826000002_prng_and_challenge_scoring.sql
-- Status: Canonical Baseline

-- 1. 32-BIT INTEGER MULTIPLICATION (Math.imul emulation in PostgreSQL)
CREATE OR REPLACE FUNCTION public.imul32(a BIGINT, b BIGINT)
RETURNS BIGINT AS $$
DECLARE
    a_lo BIGINT;
    a_hi BIGINT;
    b_lo BIGINT;
    b_hi BIGINT;
    lo_prod BIGINT;
    mid_prod BIGINT;
BEGIN
    a_lo := a & 65535;
    a_hi := (a >> 16) & 65535;
    b_lo := b & 65535;
    b_hi := (b >> 16) & 65535;
    
    lo_prod := (a_lo * b_lo) & 4294967295;
    mid_prod := (((a_hi * b_lo) + (a_lo * b_hi)) & 65535) << 16;
    
    RETURN (lo_prod + mid_prod) & 4294967295;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- 2. CANONICAL MULBERRY32 GENERATOR IN PLPGSQL
CREATE OR REPLACE FUNCTION public.mulberry32_step(INOUT state BIGINT, OUT next_u32 BIGINT)
AS $$
DECLARE
    t BIGINT;
BEGIN
    state := (state + 1831565813) & 4294967295; -- 0x6D2B79F5
    t := state;
    t := public.imul32(t # (t >> 15), t | 1);
    t := (t # (t + public.imul32(t # (t >> 7), 61))) & 4294967295;
    next_u32 := (t # (t >> 14)) & 4294967295;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- 3. REACTION AUTHORITATIVE SCORING
CREATE OR REPLACE FUNCTION public.score_reaction(
    p_round_seed BIGINT,
    p_evidence JSONB,
    OUT calculated_score INT,
    OUT validation_res public.validation_status,
    OUT metric_text TEXT,
    OUT raw_val NUMERIC
) AS $$
DECLARE
    t_rx INT;
    is_fault BOOLEAN;
    curve_val NUMERIC;
BEGIN
    is_fault := COALESCE((p_evidence->>'is_fault')::BOOLEAN, FALSE);
    t_rx := COALESCE((p_evidence->>'reaction_time_ms')::INT, 0);
    raw_val := t_rx;

    IF is_fault OR t_rx < 100 THEN
        calculated_score := 0;
        validation_res := 'EARLY_FAULT';
        metric_text := 'FAULT';
        RETURN;
    END IF;

    IF t_rx > 1000 THEN
        calculated_score := 0;
        validation_res := 'TIMEOUT';
        metric_text := 'TIMEOUT';
        RETURN;
    END IF;

    validation_res := 'VALID';
    metric_text := t_rx || ' ms';

    IF t_rx >= 100 AND t_rx <= 160 THEN
        calculated_score := 1000;
    ELSIF t_rx > 160 AND t_rx <= 600 THEN
        curve_val := 1000.0 * (1.0 - POWER(((t_rx - 160)::NUMERIC / 440.0), 1.3));
        calculated_score := GREATEST(0, ROUND(curve_val)::INT);
    ELSE
        calculated_score := 0;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 4. MEMORY AUTHORITATIVE SCORING
CREATE OR REPLACE FUNCTION public.score_memory(
    p_sequence_length INT,
    p_evidence JSONB,
    OUT calculated_score INT,
    OUT validation_res public.validation_status,
    OUT metric_text TEXT,
    OUT raw_val NUMERIC
) AS $$
DECLARE
    k INT;
    t_comp INT;
    speed_bonus NUMERIC;
BEGIN
    k := COALESCE((p_evidence->>'correct_count')::INT, 0);
    t_comp := COALESCE((p_evidence->>'completion_time_ms')::INT, 6000);
    raw_val := k;

    IF k < 0 OR k > p_sequence_length THEN
        calculated_score := 0;
        validation_res := 'FLAGGED';
        metric_text := 'INVALID';
        RETURN;
    END IF;

    validation_res := 'VALID';
    metric_text := k || ' / ' || p_sequence_length;

    IF k = 0 THEN
        calculated_score := 0;
    ELSIF k < p_sequence_length THEN
        calculated_score := ROUND(750.0 * (k::NUMERIC / p_sequence_length::NUMERIC))::INT;
    ELSE
        -- 100% Accuracy: 750 base + speed bonus up to 250
        speed_bonus := 250.0 * GREATEST(0.0, 1.0 - (t_comp::NUMERIC / 6000.0));
        calculated_score := 750 + ROUND(speed_bonus)::INT;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5. PRECISION AUTHORITATIVE SCORING
CREATE OR REPLACE FUNCTION public.score_precision(
    p_target_x NUMERIC,
    p_target_y NUMERIC,
    p_radius NUMERIC,
    p_evidence JSONB,
    OUT calculated_score INT,
    OUT validation_res public.validation_status,
    OUT metric_text TEXT,
    OUT raw_val NUMERIC
) AS $$
DECLARE
    x_touch NUMERIC;
    y_touch NUMERIC;
    t_tap INT;
    dist NUMERIC;
    acc_ratio NUMERIC;
    dist_score NUMERIC;
    speed_score NUMERIC;
BEGIN
    x_touch := COALESCE((p_evidence->>'x_touch')::NUMERIC, 0.0);
    y_touch := COALESCE((p_evidence->>'y_touch')::NUMERIC, 0.0);
    t_tap := COALESCE((p_evidence->>'time_to_tap_ms')::INT, 1250);

    -- Coordinate bounds check
    IF x_touch < 0.0 OR x_touch > 1.0 OR y_touch < 0.0 OR y_touch > 1.0 THEN
        calculated_score := 0;
        validation_res := 'FLAGGED';
        metric_text := 'FLAGGED';
        raw_val := 1.0;
        RETURN;
    END IF;

    dist := SQRT(POWER(x_touch - p_target_x, 2) + POWER(y_touch - p_target_y, 2));
    raw_val := dist;

    IF t_tap < 0 THEN
        calculated_score := 0;
        validation_res := 'FLAGGED';
        metric_text := 'FLAGGED';
        RETURN;
    END IF;

    IF t_tap > 1200 THEN
        calculated_score := 0;
        validation_res := 'TIMEOUT';
        metric_text := 'TIMEOUT';
        RETURN;
    END IF;

    IF dist > p_radius THEN
        calculated_score := 0;
        validation_res := 'VALID';
        metric_text := 'MISS';
        RETURN;
    END IF;

    validation_res := 'VALID';
    acc_ratio := 1.0 - (dist / p_radius);
    metric_text := TO_CHAR(acc_ratio * 100.0, 'FM990.0') || '%';

    dist_score := 850.0 * POWER(acc_ratio, 1.5);
    speed_score := 150.0 * GREATEST(0.0, 1.0 - (t_tap::NUMERIC / 1200.0));
    calculated_score := ROUND(dist_score + speed_score)::INT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
