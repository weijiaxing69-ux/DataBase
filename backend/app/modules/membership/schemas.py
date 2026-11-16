"""成员4的设备联调所需登录结构；其他会员业务由对应成员继续实现。"""
from pydantic import BaseModel, ConfigDict, Field, field_serializer


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=1024, repr=False)


class AccountContext(BaseModel):
    account_id: int
    user_id: int | None = None
    roles: list[str]
    permissions: list[str]
    home_path: str = "/dashboard"

    @field_serializer("account_id", "user_id", when_used="json")
    def _id(self, value):
        return str(value) if value is not None else None


class LoginResponse(BaseModel):
    access_token: str = Field(repr=False)
    token_type: str = "bearer"
    expires_in: int
    account: AccountContext


class EmptyRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
