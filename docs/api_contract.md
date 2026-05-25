# Rent App — API Contract Fase 1

## Decisión definitiva

El contrato oficial usa JSON en inglés con `snake_case`.

Quedan eliminados del contrato:

- `id_inmueble`
- `precio_bs`
- `tipo_operacion`
- `tipo_inmueble`
- `imagen_url`
- `imagenes`
- `amenidades`
- `accion`
- `interaccion`
- `/api/v1/interaccion`
- `/api/v1/match`
- `/api/v1/matches/{user_id}`

## Propiedad resumida

```json
{
  "id": "uuid",
  "title": "Departamento en Equipetrol",
  "description": "Departamento moderno cerca de restaurantes.",
  "price": 3500.0,
  "currency": "BOB",
  "operation_type": "Alquiler",
  "property_type": "Departamento",
  "zone": "Equipetrol",
  "image_url": "https://...",
  "images": ["https://..."],
  "amenities": ["Piscina", "Garaje"]
}
```

## Lista paginada

```json
{
  "items": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 0,
    "has_next": false
  }
}
```

## Onboarding request

```json
{
  "budget": 3500.0,
  "operation_type": "Alquiler",
  "preferred_zone": "Equipetrol"
}
```

## Swipe request

```json
{
  "property_id": "uuid",
  "action": "like"
}
```

## Swipe response

```json
{
  "status": "success",
  "message": "Interacción procesada correctamente.",
  "property_id": "uuid",
  "action": "like",
  "is_match": true
}
```

## Matches buyer

```txt
GET /api/v1/matches
```

No se manda `user_id`; FastAPI obtiene el usuario desde el Bearer token.

## Market evaluate request

```json
{
  "price": 3500.0,
  "operation_type": "Alquiler",
  "zone": "Equipetrol",
  "property_type": "Departamento"
}
```

## Market evaluate response

```json
{
  "statistical_analysis": {
    "mean": 3400.0,
    "median": 3300.0,
    "min_price": 3000.0,
    "max_price": 4000.0,
    "standard_deviation": 450.0,
    "coefficient_of_variation": 13.0,
    "quartiles": {
      "q1": 3000.0,
      "q2": 3300.0,
      "q3": 3700.0
    },
    "sample_size": 32
  },
  "price_verdict": "fair_price"
}
```

## Error estándar

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "La solicitud contiene datos inválidos.",
    "details": {}
  }
}
```

