from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    supabase_url: str = ""
    supabase_service_role_key: str = ""
    device_api_key: str = "change-me-to-a-long-random-string"
    # Allows GET endpoints without a Supabase user JWT (classroom/demo mode).
    dev_allow_anon: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
