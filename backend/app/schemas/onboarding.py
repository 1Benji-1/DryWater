from pydantic import BaseModel, Field


class OnboardingRequest(BaseModel):
    """Datos iniciales para generar el primer mazo de propiedades.

    En Fase 2 el user_id ya no se escribe manualmente.
    El backend lo toma desde el token Supabase.
    """

    presupuesto_max: float = Field(..., gt=0, examples=[4000])
    tipo_operacion: str = Field(..., min_length=1, examples=["Alquiler"])
    zona_preferida: str = Field(..., min_length=1, examples=["Equipetrol"])


class OnboardingResponse(BaseModel):
    """Respuesta del onboarding con información útil para Flutter."""

    status: str = Field(default="success")
    message: str
    user_id: str
    available_properties: int = Field(default=0, ge=0)
