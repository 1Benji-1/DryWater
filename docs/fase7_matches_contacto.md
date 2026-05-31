# Fase 7 — Matches y contacto

## Qué cambia

Esta fase convierte los likes en una oportunidad real de contacto:

- El buyer lista matches desde la tabla `matches`, no desde `swipes`.
- Cada match tiene `match_id`, `status`, `property` y datos básicos del owner.
- Se agrega detalle de match con contacto por WhatsApp.
- Al abrir WhatsApp, el match se marca como `contacted`.
- El owner puede ver interesados y cambiar estado a:
  - `active`
  - `contacted`
  - `archived`

## Archivos principales tocados

Backend:

- `backend/app/domain/matches/match_status.py`
- `backend/app/schemas/match.py`
- `backend/app/infrastructure/repositories/match_repo.py`
- `backend/app/services/match_service.py`
- `backend/app/api/v1/endpoints/matches.py`

Frontend:

- `frontend/lib/features/matches/...`
- `frontend/lib/services/api_service.dart`
- `frontend/lib/core/router/app_router.dart`
- `frontend/lib/core/router/route_names.dart`
- `frontend/lib/features/owner_dashboard/presentation/dashboard_screen.dart`

Supabase manual:

- Ejecutar `supabase/fase7_match_status_constraint.sql` en SQL Editor.
