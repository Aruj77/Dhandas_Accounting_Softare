from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Swap providers by changing this value only (see providers/factory.py)
    gst_provider: str = "gstinapi"
    gstinapi_api_key: str = ""
    appyflow_key_secret: str = ""
    request_timeout: int = 10

    class Config:
        env_file = ".env"


settings = Settings()
