-- ============================================================
-- RENT APP - FASE 6 OPCIONAL
-- Zonas y conexiones para grafo cargado desde DB.
-- Ejecutar manualmente en Supabase SQL Editor si todavía no existen.
-- ============================================================

create table if not exists public.zones (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  city text not null default 'Santa Cruz',
  created_at timestamptz not null default now()
);

create table if not exists public.zone_connections (
  id uuid primary key default gen_random_uuid(),
  from_zone_id uuid not null references public.zones(id) on delete cascade,
  to_zone_id uuid not null references public.zones(id) on delete cascade,
  distance_score int not null default 1,
  created_at timestamptz not null default now(),
  unique(from_zone_id, to_zone_id)
);

insert into public.zones (name)
values
  ('Equipetrol'),
  ('Centro'),
  ('Zona Norte'),
  ('Zona Sur'),
  ('Urubó')
on conflict (name) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Zona Norte'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Centro'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Urubó'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Zona Sur'
where z1.name = 'Centro'
on conflict (from_zone_id, to_zone_id) do nothing;
