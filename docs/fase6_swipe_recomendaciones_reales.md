# Rent App — Fase 6 aplicada: Swipe y recomendaciones reales

Este script aplica únicamente la Fase 6 estructural.

## Cambios backend

- `backend/app/services/recommendation_service.py`
- `backend/app/domain/recommendation/scoring.py`
- `backend/app/domain/graphs/zone_graph.py`
- `backend/app/infrastructure/repositories/zone_repo.py`
- `backend/app/api/v1/endpoints/properties.py`
- `backend/app/services/swipe_service.py`
- `backend/app/schemas/swipe.py`
- Ajustes en repositorios de propiedades, swipes y matches.

## Cambios frontend

- `ApiService.fetchProperties()` ahora consume:

```txt
GET /api/v1/properties/recommendations
```

- `sendSwipeAction()` ahora devuelve `SwipeResult`.
- El feed invalida recomendaciones después de un swipe.

## Qué NO toca

- No toca Git.
- No instala dependencias.
- No modifica auth visual.
- No modifica market.
- No modifica owner dashboard salvo que el feed se refresque tras swipes.
- No hace deploy.

## Comprobaciones manuales recomendadas

Backend:

```bash
cd backend
python -m compileall app main.py
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Flutter:

```bash
cd frontend
flutter analyze
./run_linux.sh
```

Supabase opcional:

Si no tienes `zones` y `zone_connections`, puedes ejecutar manualmente:

```txt
backend/supabase/fase6_zone_connections_optional.sql
```

Si no lo ejecutas, el backend usa fallback con `city_graph.py`.
