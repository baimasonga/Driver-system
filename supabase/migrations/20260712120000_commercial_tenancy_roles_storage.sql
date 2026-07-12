begin;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status text not null default 'active' check (status in ('active','suspended','closed')),
  created_at timestamptz not null default now()
);

insert into public.organizations(id,name,slug)
values ('00000000-0000-4000-8000-000000000001','Fleet Control Organization','fleet-control')
on conflict (id) do nothing;

alter table public.profiles add column if not exists organization_id uuid
  references public.organizations(id) on delete restrict;
update public.profiles set organization_id='00000000-0000-4000-8000-000000000001'
where organization_id is null;
alter table public.profiles alter column organization_id set not null;

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check
  (role in ('admin','manager','approver','dispatcher','gate_officer','storekeeper','garage','driver'));

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into public.profiles(id,role,full_name,email,organization_id)
  values (new.id,coalesce(new.raw_app_meta_data->>'role','driver'),
    coalesce(new.raw_user_meta_data->>'full_name',''),new.email,
    coalesce((new.raw_app_meta_data->>'organization_id')::uuid,
      '00000000-0000-4000-8000-000000000001'::uuid));
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['vehicles','drivers','trips','fuel_requests','maintenance_requests',
    'exception_records','incidents','audit_logs','policy_rules','spare_parts','tyres','inspections',
    'maintenance_part_movements'] loop
    execute format('alter table public.%I add column if not exists organization_id uuid references public.organizations(id) on delete restrict', t);
    execute format('update public.%I set organization_id=$1 where organization_id is null', t)
      using '00000000-0000-4000-8000-000000000001'::uuid;
    execute format('alter table public.%I alter column organization_id set not null', t);
    execute format('create index if not exists %I on public.%I(organization_id)', t || '_organization_idx', t);
  end loop;
end $$;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.assign_row_organization()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_org uuid;
begin
  select organization_id into v_org from public.profiles where id=(select auth.uid());
  if v_org is null then raise exception 'No organization is assigned to this account'; end if;
  new.organization_id := v_org;
  return new;
end $$;
revoke all on function private.assign_row_organization() from public, anon, authenticated;

do $$
declare t text;
begin
  foreach t in array array['vehicles','drivers','trips','fuel_requests','maintenance_requests',
    'exception_records','incidents','audit_logs','policy_rules','spare_parts','tyres','inspections',
    'maintenance_part_movements'] loop
    execute format('drop trigger if exists assign_organization on public.%I', t);
    execute format('create trigger assign_organization before insert on public.%I for each row execute function private.assign_row_organization()', t);
  end loop;
end $$;

-- Replace broad manager policies with organization-scoped policies.
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies
    where schemaname='public' and policyname like 'manager%' loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

do $$
declare t text;
begin
  foreach t in array array['vehicles','drivers','trips','fuel_requests','maintenance_requests',
    'exception_records','incidents','audit_logs','policy_rules','spare_parts','tyres','inspections',
    'maintenance_part_movements'] loop
    execute format($p$
      create policy "organization administrators manage" on public.%I for all to authenticated
      using (organization_id=(select p.organization_id from public.profiles p where p.id=(select auth.uid()))
        and exists(select 1 from public.profiles p where p.id=(select auth.uid())
          and p.role in ('admin','manager')))
      with check (organization_id=(select p.organization_id from public.profiles p where p.id=(select auth.uid()))
        and exists(select 1 from public.profiles p where p.id=(select auth.uid())
          and p.role in ('admin','manager')))
    $p$, t);
  end loop;
end $$;

-- Operational roles receive only the tables/actions needed for their work.
create policy "approver read trips" on public.trips for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'));
create policy "approver update trips" on public.trips for update to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));
create policy "approver read fuel" on public.fuel_requests for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'));
create policy "approver update fuel" on public.fuel_requests for update to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));
create policy "approver read maintenance" on public.maintenance_requests for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'));
create policy "approver update maintenance" on public.maintenance_requests for update to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='approver'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));

create policy "dispatcher manage trips" on public.trips for all to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='dispatcher'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));
create policy "operations read vehicles" on public.vehicles for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role in ('approver','dispatcher','gate_officer','garage')));
create policy "operations read drivers" on public.drivers for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role in ('approver','dispatcher','gate_officer','garage')));
create policy "gate manage trips" on public.trips for select to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='gate_officer'));
create policy "gate update trips" on public.trips for update to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='gate_officer'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));

create policy "storekeeper manage parts" on public.spare_parts for all to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='storekeeper'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));
create policy "storekeeper manage part movements" on public.maintenance_part_movements for all to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='storekeeper'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));
create policy "garage update work orders" on public.maintenance_requests for update to authenticated using
  (organization_id=(select organization_id from public.profiles where id=(select auth.uid())) and
   exists(select 1 from public.profiles where id=(select auth.uid()) and role='garage'))
  with check (organization_id=(select organization_id from public.profiles where id=(select auth.uid())));

alter table public.organizations enable row level security;
revoke all on public.organizations from anon;
grant select on public.organizations to authenticated;
create policy "members read organization" on public.organizations for select to authenticated
using (id=(select p.organization_id from public.profiles p where p.id=(select auth.uid())));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('fleet-evidence','fleet-evidence',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public=false,file_size_limit=10485760,
  allowed_mime_types=excluded.allowed_mime_types;

create policy "organization evidence read" on storage.objects for select to authenticated
using (bucket_id='fleet-evidence' and (storage.foldername(name))[1]=
  (select p.organization_id::text from public.profiles p where p.id=(select auth.uid())));
create policy "organization evidence upload" on storage.objects for insert to authenticated
with check (bucket_id='fleet-evidence' and (storage.foldername(name))[1]=
  (select p.organization_id::text from public.profiles p where p.id=(select auth.uid()))
  and (storage.foldername(name))[2]=(select auth.uid())::text);

commit;
