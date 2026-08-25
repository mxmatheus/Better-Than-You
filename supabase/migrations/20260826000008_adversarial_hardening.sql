-- BETTER THAN YOU — Adversarial & Anti-Cheat Hardening Migration
-- Migration: 20260826000008_adversarial_hardening.sql
-- Status: Canonical Baseline

-- 1. PREVENT DIRECT CLIENT MUTATION OF PROFILE COMPETITIVE FIELDS
CREATE OR REPLACE FUNCTION public.enforce_profile_field_protection()
RETURNS TRIGGER AS $$
BEGIN
    -- If executed by standard authenticated or anon client role
    IF current_user IN ('authenticated', 'anon') THEN
        IF (NEW.mmr <> OLD.mmr OR
            NEW.provisional_matches_remaining <> OLD.provisional_matches_remaining OR
            NEW.matches_played <> OLD.matches_played OR
            NEW.wins <> OLD.wins OR
            NEW.losses <> OLD.losses OR
            NEW.draws <> OLD.draws OR
            NEW.rank_tier <> OLD.rank_tier) THEN
            RAISE EXCEPTION 'Direct client mutation of competitive rating, rank, or match statistics is prohibited';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_profile_competitive_fields ON public.profiles;
CREATE TRIGGER trg_protect_profile_competitive_fields
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.enforce_profile_field_protection();

-- 2. LOCK DOWN DAILY_SUBMISSIONS DIRECT INSERT/UPDATE (RPC-ONLY SUBMISSION)
DROP POLICY IF EXISTS "Users can submit own daily challenge" ON public.daily_submissions;

-- Authenticated users may ONLY view daily submissions; all inserts/updates occur strictly via SECURITY DEFINER RPCs
-- (start_or_resume_daily_challenge and submit_daily_round_evidence)

-- 3. AUDIT & LOGGING TRIGGER FOR SUSPICIOUS TELEMETRY (Telemetry anomaly logging)
CREATE OR REPLACE FUNCTION public.log_telemetry_anomaly(
    p_user_id UUID,
    p_action TEXT,
    p_details JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.audit_logs (
        user_id,
        action,
        details
    ) VALUES (
        p_user_id,
        p_action,
        p_details
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.log_telemetry_anomaly(UUID, TEXT, JSONB) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.log_telemetry_anomaly(UUID, TEXT, JSONB) TO authenticated;
