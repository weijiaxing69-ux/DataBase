from datetime import datetime, timezone
from decimal import Decimal

from fastapi.encoders import jsonable_encoder


def wire(value):
    if isinstance(value, dict):
        return {key: str(item) if key.endswith("_id") and type(item) is int else wire(item)
                for key, item in value.items()}
    if isinstance(value, list):
        return [wire(item) for item in value]
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, datetime):
        return (value if value.tzinfo else value.replace(tzinfo=timezone.utc)).isoformat()
    return jsonable_encoder(value)
