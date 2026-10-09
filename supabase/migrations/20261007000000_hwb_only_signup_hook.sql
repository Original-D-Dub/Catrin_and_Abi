-- Hwb-only sign-up: server-side enforcement.
--
-- The app signs out non-Hwb accounts itself (AuthProvider
-- ._enforceHwbOnlyIfNeeded), but a client-side check can be bypassed. This
-- "before user created" Auth hook makes Supabase refuse to create any
-- non-anonymous account whose email isn't on a Hwb domain. Keep the domain
-- list in step with AppConfig.hwbEmailDomains.
--
-- Running this migration only creates the function. It has no effect until
-- the hook is switched on, so do that at the same time as setting
-- AppConfig.hwbOnlyLogin to true:
--
--   1. Dashboard → Authentication → Hooks → "Before User Created"
--      → Postgres function → public.hook_hwb_only_before_user_created.
--   2. Dashboard → Authentication → Providers → Azure → "Azure Tenant URL"
--      → https://login.microsoftonline.com/<Hwb tenant ID>, so only Hwb
--      Microsoft accounts can complete sign-in or be linked at all.
--
-- What this does not cover: linking an identity to an existing account
-- doesn't create a user, so it doesn't run this hook. Linking a Hwb
-- identity is covered by the tenant restriction in step 2. Adding an email
-- and password to an anonymous account (AuthProvider.linkEmail) is not
-- covered, so hide that option, or turn off the Email provider, once
-- Hwb-only is live.

create or replace function public.hook_hwb_only_before_user_created(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  is_anonymous boolean := coalesce((event -> 'user' ->> 'is_anonymous')::boolean, false);
  email text := lower(coalesce(event -> 'user' ->> 'email', ''));
  domain text := split_part(email, '@', 2);
begin
  -- Anonymous players (no account yet) are always allowed.
  if is_anonymous then
    return '{}'::jsonb;
  end if;

  if domain = 'hwbcymru.net' or domain like '%.hwbcymru.net' then
    return '{}'::jsonb;
  end if;

  return jsonb_build_object(
    'error', jsonb_build_object(
      'http_code', 403,
      'message', 'Please sign in with your Hwb account.'
    )
  );
end;
$$;

-- Only the Auth service may call the hook.
grant usage on schema public to supabase_auth_admin;
grant execute on function public.hook_hwb_only_before_user_created(jsonb)
  to supabase_auth_admin;
revoke execute on function public.hook_hwb_only_before_user_created(jsonb)
  from authenticated, anon, public;
