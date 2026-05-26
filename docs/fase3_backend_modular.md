# Rent App — Fase 3 Backend Modular

Este refactor separa el backend siguiendo:

```txt
endpoint -> schema -> service -> repository -> Supabase/PostgreSQL
```

## Cambios aplicados

- `backend/main.py` ahora usa `app.api.v1.router`.
- `backend/app/api/routes.py` quedó como legacy sin rutas activas.
- Endpoints separados en `backend/app/api/v1/endpoints/`.
- Services implementados en `backend/app/services/`.
- Repositorios separados en `backend/app/infrastructure/repositories/`.
- Market se movió a `MarketService`.
- Swipes se movieron a `SwipeService`.
- Matches se movieron a `MatchService`.
- Owner properties se movió a `OwnerPropertyService`.
- Perfil/roles se movió a `ProfileService`.

## Comprobaciones rápidas

```bash
cd backend
python -m compileall app main.py
python -m pytest -q
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Luego abrir:

```txt
http://127.0.0.1:8000/health
http://127.0.0.1:8000/api/v1/health
http://127.0.0.1:8000/docs
```
