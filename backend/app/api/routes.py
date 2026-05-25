"""Rutas v1 de Rent App API conectadas a Supabase."""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import CurrentUser, get_current_user
from app.domain.market.analyzer import MarketAnalyzer
from app.domain.matching.matcher import MatchMaker
from app.infrastructure.repositories.property_repo import repo_inmuebles
from app.schemas.common import PaginationMeta
from app.schemas.market import (
    MarketEvaluationRequest,
    MarketEvaluationResponse,
    MarketStatisticsResponse,
    QuartilesResponse,
)
from app.schemas.match import MatchListResponse, MatchRequest
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


def normalizar_stats(
    stats: dict[str, Any],
    sample_size: int,
    precios: list[float],
) -> MarketStatisticsResponse:
    """Convierte stats heredadas del dominio a un schema estable."""

    cuartiles = stats.get("cuartiles", {})
    precios_ordenados = sorted(precios)

    return MarketStatisticsResponse(
        mean=stats.get("media", 0),
        median=cuartiles.get("Q2"),
        min_price=precios_ordenados[0] if precios_ordenados else None,
        max_price=precios_ordenados[-1] if precios_ordenados else None,
        standard_deviation=stats.get("desviacion_std"),
        coefficient_of_variation=stats.get("cv"),
        quartiles=QuartilesResponse(
            q1=cuartiles.get("Q1", 0),
            q2=cuartiles.get("Q2", 0),
            q3=cuartiles.get("Q3", 0),
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
        max_budget=request.presupuesto_max,
        operation_type=request.tipo_operacion,
        preferred_zone=request.zona_preferida,
    )

    available = repo_inmuebles.count_available_for_preferences(
        max_budget=request.presupuesto_max,
        operation_type=request.tipo_operacion,
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


@router.delete("/owner/properties/{property_id}")
async def eliminar_propiedad_owner(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> dict[str, str]:
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

    return {"status": "success", "message": "Propiedad ocultada correctamente."}


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


@router.post("/interaccion", response_model=SwipeResponse)
async def registrar_interaccion_legacy(
    swipe: SwipeRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SwipeResponse:
    """Endpoint heredado temporal para compatibilidad."""

    return await registrar_swipe(swipe=swipe, current_user=current_user)


@router.get("/matches/{user_id}", response_model=MatchListResponse)
async def obtener_matches_usuario(
    user_id: str,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> MatchListResponse:
    """Devuelve propiedades likeadas por el usuario autenticado."""

    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No puedes consultar matches de otro usuario.",
        )

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


@router.patch("/matches/{match_id}/status")
async def actualizar_estado_match(
    match_id: str,
    request: MatchStatusUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> dict[str, str]:
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

    return {"status": "success", "message": "Match actualizado correctamente."}


@router.post("/match")
def calcular_match(
    request: MatchRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> dict[str, list[dict]]:
    """Endpoint académico de compatibilidad por conjuntos."""

    rows = repo_inmuebles.list_available_cards()
    legacy_like_rows = []

    for row in rows:
        legacy_like_rows.append(
            {
                "id_inmueble": row.get("id"),
                "precio_bs": row.get("price"),
                "amenidades": "|".join(row.get("amenities") or []),
                "zona": row.get("zone"),
                "tipo_operacion": row.get("operation_type"),
                "tipo_inmueble": row.get("property_type"),
            }
        )

    class _AmenityMatrixAdapter:
        def obtener_amenidades_de_inmueble(self, property_id: str) -> set[str]:
            for row in rows:
                if str(row.get("id")) == property_id:
                    return set(row.get("amenities") or [])
            return set()

    resultados = MatchMaker.buscar_mejores_opciones(
        requisitos_cliente=set(request.requisitos),
        presupuesto_max=request.presupuesto_max,
        todos_los_inmuebles=legacy_like_rows,
        matriz_amenidades=_AmenityMatrixAdapter(),
    )
    return {"matches": resultados}


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
        statistical_analysis=normalizar_stats(stats, len(precios), precios),
        price_verdict=evaluacion,
    )
