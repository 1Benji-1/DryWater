from functools import lru_cache

from supabase import Client, create_client

from app.core.config import get_settings


@lru_cache
def get_supabase_client() -> Client:
    """Devuelve un cliente Supabase con permisos de backend."""

    settings = get_settings()
    settings.validate_supabase_config()

    return create_client(settings.supabase_url, settings.supabase_secret_key)
