from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]

class Settings(BaseSettings):
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str
    db_name: str = "charging_platform_test"
    # 持久保存的 Fernet 密钥；不可随应用启动重新生成或提交到仓库。
    phone_encryption_key: str = ""
    # JWT 签名密钥；演示入口会在独立进程内生成，正式环境通过 .env 配置。
    auth_signing_key: str = ""
    auth_token_seconds: int = 3600

    model_config = SettingsConfigDict(env_file=BACKEND_DIR / ".env", env_file_encoding="utf-8")

settings = Settings()
