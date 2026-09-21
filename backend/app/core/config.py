from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Swap providers by changing this value only (see providers/factory.py)
    gst_provider: str = "gstinapi"
    gstinapi_api_key: str = ""
    appyflow_key_secret: str = ""
    request_timeout: int = 10

    database_url: str

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()