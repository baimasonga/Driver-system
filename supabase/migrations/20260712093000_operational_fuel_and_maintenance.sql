begin;

alter table public.fuel_requests
  add column if not exists payment_method text not null default 'Cash'
    check (payment_method in ('Cash', 'Fuel Card')),
  add column if not exists receipt_number text,
  add column if not exists card_transaction_reference text,
  add column if not exists unit_price numeric check (unit_price > 0),
  add column if not exists distance_since_previous_fuel_km numeric check (distance_since_previous_fuel_km >= 0),
  add column if not exists calculated_km_per_liter numeric check (calculated_km_per_liter >= 0);

create unique index if not exists fuel_requests_receipt_number_unique
  on public.fuel_requests (lower(receipt_number)) where receipt_number is not null;

create table if not exists public.maintenance_part_movements (
  id text primary key,
  maintenance_request_id text not null references public.maintenance_requests(id) on delete restrict,
  spare_part_id text references public.spare_parts(id) on delete restrict,
  vehicle_id text not null references public.vehicles(id) on delete restrict,
  part_name text not null,
  part_number text,
  removed_serial_number text not null,
  installed_serial_number text not null,
  removed_condition text not null,
  quantity integer not null default 1 check (quantity > 0),
  unit_cost numeric not null check (unit_cost >= 0),
  captured_by text not null,
  captured_at timestamptz not null default now(),
  constraint different_part_serials check (removed_serial_number <> installed_serial_number)
);

create unique index if not exists maintenance_installed_serial_unique
  on public.maintenance_part_movements(installed_serial_number);
create index if not exists maintenance_part_movements_work_order_idx
  on public.maintenance_part_movements(maintenance_request_id);
create index if not exists maintenance_part_movements_vehicle_idx
  on public.maintenance_part_movements(vehicle_id);

alter table public.maintenance_part_movements enable row level security;
grant select, insert, update, delete on public.maintenance_part_movements to authenticated;
revoke all on public.maintenance_part_movements from anon;

create policy "manager all maintenance part movements"
on public.maintenance_part_movements for all to authenticated
using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='manager'))
with check (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='manager'));

do $$ begin
  alter publication supabase_realtime add table public.maintenance_part_movements;
exception when duplicate_object then null;
end $$;

create or replace function public.consume_part_for_work_order(
  p_id text, p_maintenance_request_id text, p_spare_part_id text,
  p_vehicle_id text, p_removed_serial text, p_installed_serial text,
  p_removed_condition text, p_captured_by text
) returns void language plpgsql security invoker set search_path='' as $$
declare v_part public.spare_parts%rowtype;
begin
  select * into v_part from public.spare_parts where id=p_spare_part_id for update;
  if not found then raise exception 'Part not found'; end if;
  if v_part.stock_qty < 1 then raise exception 'Part is out of stock'; end if;
  if p_removed_serial = p_installed_serial then raise exception 'Removed and installed serial numbers must differ'; end if;
  insert into public.maintenance_part_movements
    (id,maintenance_request_id,spare_part_id,vehicle_id,part_name,part_number,
     removed_serial_number,installed_serial_number,removed_condition,unit_cost,captured_by)
  values
    (p_id,p_maintenance_request_id,p_spare_part_id,p_vehicle_id,v_part.part_name,v_part.part_number,
     p_removed_serial,p_installed_serial,p_removed_condition,v_part.unit_cost,p_captured_by);
  update public.spare_parts set stock_qty=stock_qty-1 where id=p_spare_part_id;
end; $$;

revoke all on function public.consume_part_for_work_order(text,text,text,text,text,text,text,text) from public, anon;
grant execute on function public.consume_part_for_work_order(text,text,text,text,text,text,text,text) to authenticated;

commit;
