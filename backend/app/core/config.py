import os
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Variables de configuración de la aplicación."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = Field(default="Rent App API", alias="APP_NAME")
    app_version: str = Field(default="2.0.0", alias="APP_VERSION")
    environment: str = Field(default=os.getenv("ENVIRONMENT", "development"), alias="ENVIRONMENT")
    cors_origins: str = Field(default=os.getenv("CORS_ORIGINS", "*"), alias="CORS_ORIGINS")

    supabase_url: str = Field(default="", alias="SUPABASE_URL")
    supabase_publishable_key: str = Field(default="", alias="SUPABASE_PUBLISHABLE_KEY")
    supabase_secret_key: str = Field(default="", alias="SUPABASE_SECRET_KEY")

    @property
    def parsed_cors_origins(self) -> list[str]:
        """Devuelve los orígenes CORS como lista."""

        if self.cors_origins.strip() == "*":
            return ["*"]

        return [
            origin.strip()
            for origin in self.cors_origins.split(",")
            if origin.strip()
        ]

    def validate_supabase_config(self) -> None:
        """Valida que Supabase esté configurado antes de usarlo."""

        missing_values = []

        if not self.supabase_url:
            missing_values.append("SUPABASE_URL")
        if not self.supabase_secret_key:
            missing_values.append("SUPABASE_SECRET_KEY")

        if missing_values:
            joined = ", ".join(missing_values)
            raise RuntimeError(f"Faltan variables de entorno requeridas: {joined}")


@lru_cache
def get_settings() -> Settings:
    """Obtiene configuración cacheada."""

    return Settings()
