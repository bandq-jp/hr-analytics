from __future__ import annotations

from functools import lru_cache

from pydantic import Field, HttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration sourced from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    gcp_project: str = Field(..., alias="GCP_PROJECT")
    gcp_region: str = Field(..., alias="GCP_REGION")
    supabase_url: HttpUrl = Field(..., alias="SUPABASE_URL")
    supabase_key: str = Field(..., alias="SUPABASE_KEY")
    database_url: str = Field(..., alias="DATABASE_URL")

    sync_batch_size: int = Field(1000, alias="SYNC_BATCH_SIZE")
    timezone: str = Field("Asia/Tokyo", alias="APP_TIMEZONE")
    ingest_full_refresh: bool = Field(False, alias="INGEST_FULL_REFRESH")


@lru_cache
def get_settings() -> Settings:
    """Provide a cached Settings instance."""

    return Settings()
