-- ============================================================
-- RENT APP - FASE 7
-- Diagnóstico y corrección de likes/matches con tu esquema actual.
-- Ejecuta por partes en Supabase SQL Editor.
-- ============================================================

-- 1) Ver usuarios disponibles para elegir un owner de prueba.
select
  id,
  full_name,
  role,
  phone,
  created_at
from public.profiles
order by created_at desc;

-- 2) Ver propiedades sin propietario.
-- Si owner_id está null, el backend puede guardar swipes/likes,
-- pero NO puede crear un match formal para el owner.
select
  id,
  legacy_id,
  title,
  owner_id,
  status,
  created_at
from public.properties
order by created_at asc;

-- 3) Ver últimos swipes.
select
  s.id,
  s.user_id,
  pr.full_name as buyer_name,
  s.property_id,
  p.title,
  s.action,
  s.created_at
from public.swipes s
left join public.profiles pr on pr.id = s.user_id
left join public.properties p on p.id = s.property_id
order by s.created_at desc
limit 20;

-- 4) Ver últimos matches formales.
select
  m.id,
  m.buyer_id,
  buyer.full_name as buyer_name,
  m.owner_id,
  owner.full_name as owner_name,
  m.property_id,
  p.title,
  m.status,
  m.created_at
from public.matches m
left join public.profiles buyer on buyer.id = m.buyer_id
left join public.profiles owner on owner.id = m.owner_id
left join public.properties p on p.id = m.property_id
order by m.created_at desc
limit 20;

-- ============================================================
-- 5) FIX PARA PROPIEDADES SEED SIN OWNER
-- ============================================================
-- IMPORTANTE:
-- - Primero crea/inicia sesión con DOS cuentas en la app:
--   A) una cuenta owner/propietario
--   B) una cuenta buyer/comprador
-- - Copia el id de la cuenta owner desde el SELECT #1.
-- - Reemplaza OWNER_UUID_AQUI por ese id.
-- - NO uses como owner la misma cuenta con la que vas a dar like,
--   porque el backend bloquea swipe a propiedad propia.

-- update public.profiles
-- set role = 'owner', updated_at = now()
-- where id = 'OWNER_UUID_AQUI';

-- update public.properties
-- set owner_id = 'OWNER_UUID_AQUI', updated_at = now()
-- where owner_id is null;

-- ============================================================
-- 6) Verificación después del fix
-- ============================================================
-- Debe salir owner_id lleno en las propiedades.
-- select id, legacy_id, title, owner_id, status from public.properties order by created_at asc;

-- Después prueba en la app:
-- 1. Entra con la cuenta buyer.
-- 2. Dale like a una propiedad.
-- 3. Revisa swipes y matches con los SELECT #3 y #4.
