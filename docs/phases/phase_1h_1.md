# Phase 1H.1 — Authentication Hardening, Registration Fix & Google OAuth Report

**Status:** COMPLETE  
**Supabase Project:** `better-than-you` (`zlcqkmzwwydjodbzhiyn`)  
**Region:** `eu-central-1` (Frankfurt)  

---

## 1. Registration Bug — Root Cause Analysis

### Investigation Findings
1. **Generic Exception Masking:** In `RegisterScreen` and `SupabaseAuthRepository`, raw exceptions were caught by generic catch blocks that defaulted to `"Registration failed. Please check your details and try again."`, masking specific validation or collision causes.
2. **Trigger Collision Handling:** The initial `handle_new_user()` function performed an `INSERT INTO public.profiles` with `ON CONFLICT (id) DO NOTHING;`. If a username collision occurred (`UNIQUE(username)`), PostgreSQL threw error `23505`, failing the signup transaction and returning `"Database error saving new user"`.
3. **OAuth Metadata Fallbacks:** Google and external OAuth logins without explicit `username` metadata risked collisions or failure if not cleanly disambiguated.

---

## 2. Fixes Applied

### 2.1 Backend & Database (`20260826000009_auth_and_oauth_hardening.sql`)
- **Hardened `handle_new_user()` Trigger:**
  - Extracts and sanitizes base username (alphanumeric + underscores, 3–15 chars).
  - Explicit username collision throws a clean `USERNAME_ALREADY_TAKEN` error (`ERRCODE 23505`).
  - OAuth logins without explicit username auto-disambiguate with random suffix if collision exists.
  - Updates profile display name and avatar on subsequent logins via `ON CONFLICT (id) DO UPDATE`.
- **`check_username_available(p_username TEXT)` RPC:**
  - Added public RPC for non-authoritative client UX availability checks. Database unique constraint remains final authority.

### 2.2 Domain-Level `AuthError` Hierarchy
Created typed domain exceptions in `lib/domain/auth/auth_error.dart`:
- `InvalidCredentialsError`
- `EmailAlreadyRegisteredError`
- `UsernameAlreadyTakenError`
- `InvalidEmailError`
- `WeakPasswordError`
- `NetworkAuthError`
- `ProfileProvisioningError`
- `OAuthCancelledError`
- `OAuthFailedError`
- `UnknownAuthError`

---

## 3. Google OAuth & Android Deep Linking

- **Repository Abstraction:** `AuthRepository.signInWithGoogle()` launches OAuth flow via Supabase SDK.
- **Deep Link Callback:** Configured Android intent-filter in `android/app/src/main/AndroidManifest.xml` for `io.supabase.betterthanyou://login-callback`.
- **UI Integration:** Added "CONTINUE WITH GOOGLE" button on both `LoginScreen` and `RegisterScreen`, separated by a stylized `OR` divider.
- **Provider Status:** Flutter implementation and Android callback schemes are complete. Supabase Google OAuth provider requires enabling in the Supabase Dashboard with Google Cloud Client ID / Client Secret credentials.

---

## 4. Verification & Testing

### 4.1 Automated Test Suite
- **Auth Domain Tests (`test/unit/auth_repository_test.dart`):** Verifies all `AuthError` classifications, duplicate username rejection, duplicate email rejection, weak password rejection, username availability checks, and Google sign-in.
- **Auth Widget Tests (`test/widget/auth_widget_test.dart`):** Tests Google OAuth button rendering, divider, and specific error message banner rendering.
- **Full Suite:** **100 / 100 PASSED** (100% clean).
- **Static Analysis:** `flutter analyze` completed with **0 issues**.
- **Code Formatting:** `dart format` — 100% formatted.

---

## 5. Security Checklist
- [x] No secrets or client secrets committed.
- [x] RLS policies intact.
- [x] Competitive profile fields (`mmr`, `wins`, `losses`, `draws`, `rank_tier`) remain protected by PostgreSQL triggers.
- [x] Passwords and tokens never logged.

---

## 6. Final Verdict

**PHASE 1H.1 — COMPLETE**
