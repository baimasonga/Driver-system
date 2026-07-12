-- Harden Data API grants and prevent client-side role escalation.
-- Applied to project ceohpwcxnnbmafujyoga on 2026-07-12.

begin;

revoke all privileges on all tables in schema public from anon;

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- Profiles are authorization records. Clients may read their own profile via
-- RLS, but role and driver linkage must only be changed administratively.
revoke update, insert, delete on public.profiles from authenticated;
grant select on public.profiles to authenticated;
drop policy if exists "profiles own update" on public.profiles;

-- Audit entries must identify the signed-in user and require a valid profile.
drop policy if exists "authenticated audit insert" on public.audit_logs;
create policy "authenticated audit insert"
on public.audit_logs
for insert
to authenticated
with check (
  user_id = (select auth.uid())::text
  and exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
  )
);

commit;
