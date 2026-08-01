from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import Optional, List

class Settings(BaseSettings):
    DATABASE_URL: str
    REDIS_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    FRONTEND_URL: str = "http://localhost:3000"

    # Comma-separated list of allowed CORS origins.
    # Example in .env:  ALLOWED_ORIGINS=http://localhost:3000,https://tarang.app
    ALLOWED_ORIGINS: str = "http://localhost:3000"

    CLOUDINARY_CLOUD_NAME: Optional[str] = None
    CLOUDINARY_API_KEY: Optional[str] = None
    CLOUDINARY_API_SECRET: Optional[str] = None

    ENV: str = "development"
    PORT: int = 8000
    HOST: str = "127.0.0.1"
    RESEND_API_KEY: Optional[str] = None
    MAIL_FROM: str = "onboarding@resend.dev"


    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @property
    def allowed_origins_list(self) -> List[str]:
        """Parse the comma-separated ALLOWED_ORIGINS string into a list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]

settings = Settings()

