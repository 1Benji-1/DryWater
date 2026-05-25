from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import router
from app.core.config import get_settings
from app.schemas.common import ApiError, ErrorResponse

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "API de Rent App. Fase 2 conecta Supabase Auth, "
        "PostgreSQL y Storage con FastAPI."
    ),
    version=settings.app_version,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.parsed_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Devuelve errores HTTP con contrato estable."""

    error = ErrorResponse(
        error=ApiError(
            code=f"HTTP_{exc.status_code}",
            message=str(exc.detail),
            details={"path": str(request.url.path)},
        ),
    )

    return JSONResponse(
        status_code=exc.status_code,
        content=error.model_dump(),
        headers=getattr(exc, "headers", None),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
):
    """Devuelve errores de validación con contrato estable."""

    error = ErrorResponse(
        error=ApiError(
            code="VALIDATION_ERROR",
            message="La solicitud contiene datos inválidos.",
            details={
                "path": str(request.url.path),
                "errors": exc.errors(),
            },
        ),
    )

    return JSONResponse(status_code=422, content=error.model_dump())


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """Evita exponer errores internos al cliente."""

    error = ErrorResponse(
        error=ApiError(
            code="INTERNAL_ERROR",
            message="Ocurrió un error interno en el servidor.",
            details={"path": str(request.url.path)},
        ),
    )

    return JSONResponse(status_code=500, content=error.model_dump())


app.include_router(router, prefix="/api/v1", tags=["api-v1"])


@app.get("/health")
def health_check() -> dict[str, str]:
    """Healthcheck simple para monitoreo."""

    return {
        "status": "ok",
        "environment": settings.environment,
        "storage": "supabase",
    }


@app.get("/")
def home() -> dict[str, str]:
    """Mensaje base de la API."""

    return {"message": "Bienvenido a Rent App API"}
