-- BETTER THAN YOU — Security Hardening Migration
-- Migration: 20260826000005_security_hardening.sql
-- Status: Canonical Baseline

-- 1. SET EXPLICIT SEARCH_PATH ON ALL FUNCTIONS
ALTER FUNCTION public.imul32(BIGINT, BIGINT) SET search_path = public;
ALTER FUNCTION public.mulberry32_step(BIGINT) SET search_path = public;
ALTER FUNCTION public.score_reaction(BIGINT, JSONB) SET search_path = public;
ALTER FUNCTION public.score_memory(INT, JSONB) SET search_path = public;
ALTER FUNCTION public.score_precision(NUMERIC, NUMERIC, NUMERIC, JSONB) SET search_path = public;
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.resolve_round_internal(UUID) SET search_path = public;
ALTER FUNCTION public.settle_match_internal(UUID) SET search_path = public;
ALTER FUNCTION public.submit_round_evidence(UUID, JSONB, INT, TEXT) SET search_path = public;

-- 2. REVOKE DIRECT PUBLIC/ANON EXECUTION PRIVILEGES ON INTERNAL FUNCTIONS
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_round_internal(UUID) FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.settle_match_internal(UUID) FROM public, anon, authenticated;

-- submit_round_evidence should only be executable by authenticated users, NOT anon
REVOKE EXECUTE ON FUNCTION public.submit_round_evidence(UUID, JSONB, INT, TEXT) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.submit_round_evidence(UUID, JSONB, INT, TEXT) TO authenticated;
