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

