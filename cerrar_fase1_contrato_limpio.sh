#!/usr/bin/env bash
set -euo pipefail

if [ ! -d backend ] || [ ! -d frontend ]; then
  echo "Ejecuta este script desde la raíz del proyecto rent_app."
  exit 1
fi

mkdir -p docs
cat > docs/api_contract.md <<'EOF'
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

EOF

mkdir -p frontend/lib/features/properties/data/dto
cat > frontend/lib/features/properties/data/dto/property_dto.dart <<'EOF'
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/property.dart';

part 'property_dto.freezed.dart';

/// DTO de propiedad recibido desde FastAPI.
///
/// Contrato único oficial:
/// - id
/// - title
/// - description
/// - price
/// - currency
/// - operation_type
/// - property_type
/// - zone
/// - image_url
/// - images
/// - amenities
@freezed
class PropertyDto with _$PropertyDto {
  const PropertyDto._();

  const factory PropertyDto({
    required String id,
    required String title,
    required String description,
    required double price,
    required String currency,
    required String operationType,
    required String propertyType,
    required String zone,
    required String imageUrl,
    required List<String> imageUrls,
    required List<String> amenities,
  }) = _PropertyDto;

  factory PropertyDto.fromJson(Map<String, dynamic> json) {
    final imageUrl = _readRequiredString(json, 'image_url');
    final images = _readStringList(json['images']);

    return PropertyDto(
      id: _readRequiredString(json, 'id'),
      title: _readRequiredString(json, 'title'),
      description: _readRequiredString(json, 'description'),
      price: _readRequiredDouble(json, 'price'),
      currency: _readString(json['currency'], fallback: 'BOB'),
      operationType: _readRequiredString(json, 'operation_type'),
      propertyType: _readRequiredString(json, 'property_type'),
      zone: _readRequiredString(json, 'zone'),
      imageUrl: imageUrl,
      imageUrls: images.isEmpty ? [imageUrl] : images,
      amenities: _readStringList(json['amenities']),
    );
  }

  Property toEntity() {
    return Property(
      id: id,
      title: title,
      description: description,
      price: price,
      currency: currency,
      zone: zone,
      operationType: operationType,
      propertyType: propertyType,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      amenities: amenities,
    );
  }

  static String _readRequiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = _readString(json[key]);

    if (value.isEmpty) {
      throw FormatException('Campo requerido faltante o vacío: $key');
    }

    return value;
  }

  static double _readRequiredDouble(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is num) return value.toDouble();

    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Campo numérico inválido: $key');
    }

    return parsed;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

EOF

mkdir -p frontend/lib/features/market/data/dto
cat > frontend/lib/features/market/data/dto/market_evaluation_dto.dart <<'EOF'
/// DTO tipado para la respuesta de análisis de mercado.
class MarketEvaluationResult {
  final MarketStatistics statistics;
  final String priceVerdict;

  const MarketEvaluationResult({
    required this.statistics,
    required this.priceVerdict,
  });

  factory MarketEvaluationResult.fromJson(Map<String, dynamic> json) {
    final rawStats = json['statistical_analysis'];

    if (rawStats is! Map<String, dynamic>) {
      throw const FormatException('Campo requerido inválido: statistical_analysis');
    }

    return MarketEvaluationResult(
      statistics: MarketStatistics.fromJson(rawStats),
      priceVerdict: _readRequiredString(json, 'price_verdict'),
    );
  }
}

class MarketStatistics {
  final double mean;
  final double? median;
  final double? minPrice;
  final double? maxPrice;
  final double? standardDeviation;
  final double? coefficientOfVariation;
  final MarketQuartiles quartiles;
  final int sampleSize;

  const MarketStatistics({
    required this.mean,
    required this.median,
    required this.minPrice,
    required this.maxPrice,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.quartiles,
    required this.sampleSize,
  });

  factory MarketStatistics.fromJson(Map<String, dynamic> json) {
    final rawQuartiles = json['quartiles'];

    if (rawQuartiles is! Map<String, dynamic>) {
      throw const FormatException('Campo requerido inválido: quartiles');
    }

    return MarketStatistics(
      mean: _readRequiredDouble(json, 'mean'),
      median: _readNullableDouble(json['median']),
      minPrice: _readNullableDouble(json['min_price']),
      maxPrice: _readNullableDouble(json['max_price']),
      standardDeviation: _readNullableDouble(json['standard_deviation']),
      coefficientOfVariation: _readNullableDouble(
        json['coefficient_of_variation'],
      ),
      quartiles: MarketQuartiles.fromJson(rawQuartiles),
      sampleSize: _readRequiredInt(json, 'sample_size'),
    );
  }
}

class MarketQuartiles {
  final double q1;
  final double q2;
  final double q3;

  const MarketQuartiles({
    required this.q1,
    required this.q2,
    required this.q3,
  });

  factory MarketQuartiles.fromJson(Map<String, dynamic> json) {
    return MarketQuartiles(
      q1: _readRequiredDouble(json, 'q1'),
      q2: _readRequiredDouble(json, 'q2'),
      q3: _readRequiredDouble(json, 'q3'),
    );
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';

  if (value.isEmpty) {
    throw FormatException('Campo requerido faltante o vacío: $key');
  }

  return value;
}

double _readRequiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is num) return value.toDouble();

  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Campo numérico inválido: $key');
  }

  return parsed;
}

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Campo entero inválido: $key');
  }

  return parsed;
}

EOF

mkdir -p backend/app/schemas
cat > backend/app/schemas/onboarding.py <<'EOF'
from pydantic import BaseModel, Field


class OnboardingRequest(BaseModel):
    """Datos iniciales para generar el primer mazo de propiedades."""

    budget: float = Field(..., gt=0, examples=[4000])
    operation_type: str = Field(..., min_length=1, examples=["Alquiler"])
    preferred_zone: str = Field(..., min_length=1, examples=["Equipetrol"])


class OnboardingResponse(BaseModel):
    """Respuesta del onboarding con información útil para Flutter."""

    status: str = Field(default="success")
    message: str
    user_id: str
    available_properties: int = Field(default=0, ge=0)

EOF

mkdir -p backend/app/schemas
cat > backend/app/schemas/swipe.py <<'EOF'
from typing import Literal

from pydantic import BaseModel, Field


class SwipeRequest(BaseModel):
    """Acción del usuario autenticado sobre una propiedad."""

    property_id: str = Field(
        ...,
        examples=["b8ebc4f0-1234-1234-1234-123456789000"],
    )
    action: Literal["like", "nope"] = Field(..., examples=["like"])


class SwipeResponse(BaseModel):
    """Resultado de procesar un swipe."""

    status: str = Field(default="success")
    message: str
    property_id: str
    action: Literal["like", "nope"]
    is_match: bool = Field(default=False)

EOF

mkdir -p backend/app/schemas
cat > backend/app/schemas/market.py <<'EOF'
"""Schemas para evaluación estadística de mercado."""

from pydantic import BaseModel, Field


class MarketEvaluationRequest(BaseModel):
    """Solicitud de análisis de mercado para una propiedad."""

    price: float = Field(..., gt=0, examples=[3500])
    operation_type: str = Field(..., min_length=1, examples=["Alquiler"])
    zone: str | None = Field(default=None, examples=["Equipetrol"])
    property_type: str | None = Field(default=None, examples=["Departamento"])


class QuartilesResponse(BaseModel):
    """Cuartiles normalizados para Flutter."""

    q1: float
    q2: float
    q3: float


class MarketStatisticsResponse(BaseModel):
    """Estadísticas limpias para la UI."""

    mean: float
    median: float | None = None
    min_price: float | None = None
    max_price: float | None = None
    standard_deviation: float | None = None
    coefficient_of_variation: float | None = None
    quartiles: QuartilesResponse
    sample_size: int


class MarketEvaluationResponse(BaseModel):
    """Respuesta final del análisis de mercado."""

    statistical_analysis: MarketStatisticsResponse
    price_verdict: str

EOF

mkdir -p backend/app/schemas
cat > backend/app/schemas/match.py <<'EOF'
"""Schemas para matches."""

from pydantic import BaseModel

from app.schemas.common import PaginationMeta
from app.schemas.property import PropertySummaryResponse


class MatchListResponse(BaseModel):
    """Respuesta paginada de propiedades gustadas/matcheadas."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta

EOF

mkdir -p backend/app/domain/market
cat > backend/app/domain/market/analyzer.py <<'EOF'
# Archivo: backend/app/domain/market/analyzer.py
import math


class MarketAnalyzer:
    @staticmethod
    def calcular_estadisticas_zona(prices: list[float]) -> dict:
        """Calcula medidas estadísticas de precios comparables."""

        if not prices:
            return {}

        sorted_prices = sorted(float(price) for price in prices)
        total = len(sorted_prices)

        mean = sum(sorted_prices) / total
        variance = sum((price - mean) ** 2 for price in sorted_prices) / total
        standard_deviation = math.sqrt(variance)
        coefficient_of_variation = (
            (standard_deviation / mean) * 100 if mean > 0 else 0
        )

        def percentile(position: float) -> float:
            index = (total - 1) * position
            floor_index = math.floor(index)
            ceil_index = math.ceil(index)

            if floor_index == ceil_index:
                return sorted_prices[int(index)]

            return (
                sorted_prices[floor_index] * (ceil_index - index)
                + sorted_prices[ceil_index] * (index - floor_index)
            )

        q1 = percentile(0.25)
        median = percentile(0.50)
        q3 = percentile(0.75)

        if mean > median:
            skewness = "positive"
        elif mean < median:
            skewness = "negative"
        else:
            skewness = "symmetric"

        return {
            "mean": round(mean, 2),
            "standard_deviation": round(standard_deviation, 2),
            "coefficient_of_variation": round(coefficient_of_variation, 2),
            "quartiles": {
                "q1": round(q1, 2),
                "q2": round(median, 2),
                "q3": round(q3, 2),
            },
            "skewness": skewness,
        }

    @staticmethod
    def evaluar_precio(price_to_evaluate: float, stats: dict) -> str:
        """Clasifica un precio usando media, desviación estándar y cuartiles."""

        mean = float(stats["mean"])
        standard_deviation = float(stats["standard_deviation"])
        quartiles = stats["quartiles"]

        lower_limit = mean - standard_deviation
        upper_limit = mean + standard_deviation

        if price_to_evaluate <= quartiles["q1"] and price_to_evaluate < lower_limit:
            return "possible_bargain"

        if price_to_evaluate >= quartiles["q3"] and price_to_evaluate > upper_limit:
            return "high_price"

        return "fair_price"

EOF

mkdir -p backend/app/domain/matching
cat > backend/app/domain/matching/matcher.py <<'EOF'
# Archivo: backend/app/domain/matching/matcher.py


class MatchMaker:
    @staticmethod
    def calcular_compatibilidad(
        required_amenities: set[str],
        property_amenities: set[str],
    ) -> float:
        """Calcula el porcentaje de requisitos cubiertos por una propiedad."""

        if not required_amenities:
            return 100.0

        intersection = required_amenities.intersection(property_amenities)
        score = (len(intersection) / len(required_amenities)) * 100

        return round(score, 2)

    @staticmethod
    def buscar_mejores_opciones(
        required_amenities: set[str],
        max_budget: float,
        properties: list[dict],
    ) -> list[dict]:
        """Filtra por presupuesto y ordena propiedades por compatibilidad."""

        results = []

        for property_data in properties:
            price = float(property_data.get("price") or 0)

            if price > max_budget:
                continue

            property_amenities = set(property_data.get("amenities") or [])
            score = MatchMaker.calcular_compatibilidad(
                required_amenities=required_amenities,
                property_amenities=property_amenities,
            )
            missing_amenities = list(required_amenities.difference(property_amenities))

            if score > 0:
                results.append(
                    {
                        "id": property_data.get("id"),
                        "zone": property_data.get("zone"),
                        "price": price,
                        "match_score": score,
                        "missing_amenities": missing_amenities,
                    }
                )

        return sorted(results, key=lambda item: item["match_score"], reverse=True)

EOF

mkdir -p backend/app/api
cat > backend/app/api/routes.py <<'EOF'

"""Rutas v1 de Rent App API conectadas a Supabase."""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import CurrentUser, get_current_user
from app.domain.market.analyzer import MarketAnalyzer
from app.infrastructure.repositories.property_repo import repo_inmuebles
from app.schemas.common import PaginationMeta, SuccessResponse
from app.schemas.market import (
    MarketEvaluationRequest,
    MarketEvaluationResponse,
    MarketStatisticsResponse,
    QuartilesResponse,
)
from app.schemas.match import MatchListResponse
from app.schemas.onboarding import OnboardingRequest, OnboardingResponse
from app.schemas.owner_property import (
    MatchStatusUpdateRequest,
    OwnerMatchListResponse,
    OwnerMatchResponse,
    OwnerPropertyCreateRequest,
    OwnerPropertyListResponse,
    OwnerPropertyStatusRequest,
)
from app.schemas.profile import (
    BecomeOwnerResponse,
    ProfileResponse,
    ProfileUpdateRequest,
)
from app.schemas.property import (
    PropertyDetailResponse,
    PropertyListResponse,
    PropertySummaryResponse,
)
from app.schemas.swipe import SwipeRequest, SwipeResponse

router = APIRouter()


# ========================================================
# HELPERS
# ========================================================


def build_pagination(page: int, page_size: int, total: int) -> PaginationMeta:
    """Construye metadatos de paginación."""

    return PaginationMeta(
        page=page,
        page_size=page_size,
        total=total,
        has_next=(page * page_size) < total,
    )


def build_market_statistics(
    stats: dict[str, Any],
    sample_size: int,
    prices: list[float],
) -> MarketStatisticsResponse:
    """Convierte estadísticas del dominio al schema público de la API."""

    quartiles = stats.get("quartiles", {})
    sorted_prices = sorted(prices)

    return MarketStatisticsResponse(
        mean=float(stats.get("mean", 0)),
        median=quartiles.get("q2"),
        min_price=sorted_prices[0] if sorted_prices else None,
        max_price=sorted_prices[-1] if sorted_prices else None,
        standard_deviation=stats.get("standard_deviation"),
        coefficient_of_variation=stats.get("coefficient_of_variation"),
        quartiles=QuartilesResponse(
            q1=float(quartiles.get("q1", 0)),
            q2=float(quartiles.get("q2", 0)),
            q3=float(quartiles.get("q3", 0)),
        ),
        sample_size=sample_size,
    )


def profile_to_response(profile: dict, email: str | None = None) -> ProfileResponse:
    """Convierte fila de Supabase a ProfileResponse."""

    return ProfileResponse(
        id=str(profile.get("id")),
        email=email or profile.get("email"),
        full_name=profile.get("full_name"),
        phone=profile.get("phone"),
        role=str(profile.get("role") or "buyer"),
    )


def ensure_owner(current_user: CurrentUser) -> None:
    """Bloquea endpoints owner si el usuario no tiene rol correcto."""

    if not repo_inmuebles.is_owner_or_admin(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Necesitas activar el rol propietario.",
        )


# ========================================================
# PROFILE
# ========================================================


@router.get("/me", response_model=ProfileResponse)
async def obtener_mi_perfil(
    current_user: CurrentUser = Depends(get_current_user),
) -> ProfileResponse:
    """Devuelve perfil del usuario autenticado."""

    profile = repo_inmuebles.get_profile(
        user_id=current_user.id,
        email=current_user.email,
    )
    return profile_to_response(profile, current_user.email)


@router.patch("/me", response_model=ProfileResponse)
async def actualizar_mi_perfil(
    request: ProfileUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> ProfileResponse:
    """Actualiza nombre o teléfono del perfil."""

    profile = repo_inmuebles.update_profile(
        user_id=current_user.id,
        full_name=request.full_name,
        phone=request.phone,
        email=current_user.email,
    )
    return profile_to_response(profile, current_user.email)


@router.post("/me/become-owner", response_model=BecomeOwnerResponse)
async def activar_rol_propietario(
    current_user: CurrentUser = Depends(get_current_user),
) -> BecomeOwnerResponse:
    """Convierte al usuario actual en propietario."""

    profile = repo_inmuebles.become_owner(
        user_id=current_user.id,
        email=current_user.email,
    )

    return BecomeOwnerResponse(
        message="Rol propietario activado correctamente.",
        profile=profile_to_response(profile, current_user.email),
    )


# ========================================================
# ONBOARDING / BUYER
# ========================================================


@router.post(
    "/onboarding",
    response_model=OnboardingResponse,
    status_code=status.HTTP_201_CREATED,
)
async def iniciar_onboarding(
    request: OnboardingRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> OnboardingResponse:
    """Guarda preferencias iniciales del usuario autenticado."""

    repo_inmuebles.upsert_user_preferences(
        user_id=current_user.id,
        max_budget=request.budget,
        operation_type=request.operation_type,
        preferred_zone=request.preferred_zone,
    )

    available = repo_inmuebles.count_available_for_preferences(
        max_budget=request.budget,
        operation_type=request.operation_type,
    )

    return OnboardingResponse(
        message="Perfil inicial creado con éxito.",
        user_id=current_user.id,
        available_properties=available,
    )


@router.get("/amenities", response_model=list[str])
async def listar_amenidades(
    current_user: CurrentUser = Depends(get_current_user),
) -> list[str]:
    """Lista amenidades disponibles para formularios."""

    return repo_inmuebles.list_amenity_names()


# ========================================================
# PROPERTIES
# ========================================================


@router.get("/properties", response_model=PropertyListResponse)
async def obtener_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyListResponse:
    """Obtiene propiedades no vistas del usuario autenticado."""

    rows, total = repo_inmuebles.list_cards_for_user(
        user_id=current_user.id,
        page=page,
        page_size=page_size,
    )

    items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]

    return PropertyListResponse(
        items=items,
        pagination=build_pagination(page, page_size, total),
    )


@router.get("/properties/{property_id}", response_model=PropertyDetailResponse)
async def obtener_detalle_propiedad(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Obtiene detalle normalizado de una propiedad."""

    row = repo_inmuebles.find_card_by_id(property_id)
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El inmueble no existe.",
        )

    return PropertyDetailResponse.from_supabase_row(row)


# ========================================================
# OWNER PROPERTIES
# ========================================================


@router.get("/owner/properties", response_model=OwnerPropertyListResponse)
async def listar_mis_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerPropertyListResponse:
    """Lista propiedades creadas por el owner."""

    ensure_owner(current_user)

    rows, total = repo_inmuebles.list_owner_cards(
        owner_id=current_user.id,
        page=page,
        page_size=page_size,
    )

    items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]

    return OwnerPropertyListResponse(
        items=items,
        pagination=build_pagination(page, page_size, total),
    )


@router.post(
    "/owner/properties",
    response_model=PropertyDetailResponse,
    status_code=status.HTTP_201_CREATED,
)
async def crear_propiedad_owner(
    request: OwnerPropertyCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Crea una propiedad publicada por el owner."""

    repo_inmuebles.become_owner(
        user_id=current_user.id,
        email=current_user.email,
    )

    row = repo_inmuebles.create_owner_property(
        owner_id=current_user.id,
        payload=request.model_dump(),
    )

    return PropertyDetailResponse.from_supabase_row(row)


@router.patch(
    "/owner/properties/{property_id}/status",
    response_model=PropertyDetailResponse,
)
async def actualizar_estado_propiedad_owner(
    property_id: str,
    request: OwnerPropertyStatusRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Actualiza estado de una propiedad propia."""

    ensure_owner(current_user)

    row = repo_inmuebles.update_owner_property_status(
        owner_id=current_user.id,
        property_id=property_id,
        new_status=request.status,
    )

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La propiedad no existe o no te pertenece.",
        )

    return PropertyDetailResponse.from_supabase_row(row)


@router.delete(
    "/owner/properties/{property_id}",
    response_model=SuccessResponse,
)
async def eliminar_propiedad_owner(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Oculta una propiedad propia."""

    ensure_owner(current_user)

    deleted = repo_inmuebles.soft_delete_owner_property(
        owner_id=current_user.id,
        property_id=property_id,
    )

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La propiedad no existe o no te pertenece.",
        )

    return SuccessResponse(message="Propiedad ocultada correctamente.")


# ========================================================
# SWIPES / MATCHES
# ========================================================


@router.post("/swipes", response_model=SwipeResponse)
async def registrar_swipe(
    swipe: SwipeRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SwipeResponse:
    """Registra like/nope del usuario autenticado."""

    row = repo_inmuebles.find_card_by_id(swipe.property_id)
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El inmueble no existe.",
        )

    is_match = repo_inmuebles.record_swipe(
        user_id=current_user.id,
        property_id=swipe.property_id,
        action=swipe.action,
    )

    return SwipeResponse(
        message="Interacción procesada correctamente.",
        property_id=swipe.property_id,
        action=swipe.action,
        is_match=is_match,
    )


@router.get("/matches", response_model=MatchListResponse)
async def obtener_matches_usuario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> MatchListResponse:
    """Devuelve propiedades likeadas por el usuario autenticado."""

    rows, total = repo_inmuebles.list_match_cards(
        user_id=current_user.id,
        page=page,
        page_size=page_size,
    )
    items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]

    return MatchListResponse(
        items=items,
        pagination=build_pagination(page, page_size, total),
    )


@router.get("/owner/matches", response_model=OwnerMatchListResponse)
async def obtener_matches_propietario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerMatchListResponse:
    """Devuelve interesados en propiedades del propietario."""

    ensure_owner(current_user)

    rows, total = repo_inmuebles.list_owner_matches(
        owner_id=current_user.id,
        page=page,
        page_size=page_size,
    )

    items = [
        OwnerMatchResponse(
            match_id=row["match_id"],
            status=row["status"],
            buyer_id=row["buyer_id"],
            buyer_name=row.get("buyer_name"),
            buyer_email=row.get("buyer_email"),
            property=PropertySummaryResponse.from_supabase_row(row["property"]),
        )
        for row in rows
    ]

    return OwnerMatchListResponse(
        items=items,
        pagination=build_pagination(page, page_size, total),
    )


@router.patch(
    "/matches/{match_id}/status",
    response_model=SuccessResponse,
)
async def actualizar_estado_match(
    match_id: str,
    request: MatchStatusUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Actualiza estado active/contacted/archived."""

    updated = repo_inmuebles.update_match_status(
        user_id=current_user.id,
        match_id=match_id,
        status=request.status,
    )

    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El match no existe o no te pertenece.",
        )

    return SuccessResponse(message="Match actualizado correctamente.")


# ========================================================
# MARKET
# ========================================================


@router.post("/market/evaluate", response_model=MarketEvaluationResponse)
def evaluar_precio_mercado(
    request: MarketEvaluationRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> MarketEvaluationResponse:
    """Evalúa un precio usando comparables por operación, zona y tipo."""

    precios = repo_inmuebles.list_market_prices(
        operation_type=request.operation_type,
        zone=request.zone,
        property_type=request.property_type,
    )

    if not precios:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay datos suficientes para esa operación, zona o tipo.",
        )

    stats = MarketAnalyzer.calcular_estadisticas_zona(precios)
    evaluacion = MarketAnalyzer.evaluar_precio(request.price, stats)

    return MarketEvaluationResponse(
        statistical_analysis=build_market_statistics(stats, len(precios), precios),
        price_verdict=evaluacion,
    )

EOF


mkdir -p backend/supabase
cat > backend/supabase/property_seed.csv <<'EOF'
id,owner_id,operation_type,property_type,zone,price,amenities,images
INM-001,CI-89231,Alquiler,Departamento,Equipetrol,3500,Piscina|Gimnasio|Amoblado|Balcón,url_img1.jpg
INM-002,CI-44512,Alquiler,Casa,Zona Norte,4200,Mascotas|Churrasquera|Jardín|Garaje,url_img2.jpg
INM-003,CI-89231,Venta,Terreno,Urubó,150000,Seguridad Privada|Club House,url_img3.jpg
INM-004,CI-77190,Alquiler,Departamento,Centro,2800,Mascotas|Amoblado,url_img4.jpg
INM-005,CI-33211,Venta,Casa,Equipetrol,850000,Piscina|Churrasquera|Mascotas|Balcón|Garaje,url_img5.jpg
INM-006,CI-44512,Alquiler,Departamento,Zona Sur,2100,Parqueo,url_img6.jpg
EOF
rm -f backend/app/infrastructure/repositories/data/inmuebles.csv

python3 - <<'PY'

from pathlib import Path

# frontend/lib/services/api_service.dart
path = Path("frontend/lib/services/api_service.dart")
text = path.read_text()
text = text.replace(
    "import '../models/property.dart';",
    "import '../features/properties/domain/entities/property.dart';",
)
text = text.replace(
    "          'presupuesto_max': budget,\n"
    "          'tipo_operacion': operationType,\n"
    "          'zona_preferida': preferredZone,",
    "          'budget': budget,\n"
    "          'operation_type': operationType,\n"
    "          'preferred_zone': preferredZone,",
)
text = text.replace(
    "  Future<List<Property>> fetchMatches(String userId) async {",
    "  Future<List<Property>> fetchMatches() async {",
)
text = text.replace(
    "        '/api/v1/matches/$userId',",
    "        '/api/v1/matches',",
)
path.write_text(text)

# frontend/lib/providers/property_provider.dart
path = Path("frontend/lib/providers/property_provider.dart")
text = path.read_text()
text = text.replace(
    "import '../models/property.dart';",
    "import '../features/properties/domain/entities/property.dart';",
)
path.write_text(text)

# frontend/lib/screens/home_screen.dart
path = Path("frontend/lib/screens/home_screen.dart")
text = path.read_text()
text = text.replace(
    "import '../models/property.dart';",
    "import '../features/properties/domain/entities/property.dart';",
)
path.write_text(text)

# frontend/lib/features/owner_dashboard/presentation/dashboard_screen.dart
path = Path("frontend/lib/features/owner_dashboard/presentation/dashboard_screen.dart")
text = path.read_text()
text = text.replace(
    "import '../../../models/property.dart';",
    "import '../../properties/domain/entities/property.dart';",
)
text = text.replace(
    "  return api.fetchMatches(userId);",
    "  return api.fetchMatches();",
)
path.write_text(text)

# Elimina el puente viejo para que no vuelva a usarse.
Path("frontend/lib/models/property.dart").unlink(missing_ok=True)

PY

echo "Fase 1 limpia aplicada: contrato único, sin endpoints legacy ni parseo legacy."