import json

from ...core.database import execute
from ...core.serialization import wire


def record(db, actor, kind, target, action, *, before=None, after=None, note=None, version=None):
    """Append in the caller's transaction; no independent commit or full request logging."""
    encode = lambda value: json.dumps(wire(value), ensure_ascii=False) if value is not None else None
    execute(db, """INSERT INTO settlement_audit_event
        (object_type,object_id,action,actor_id,object_version,before_state,after_state,note)
        VALUES(:kind,:target,:action,:actor,:version,:before,:after,:note)""",
        kind=kind, target=target, action=action, actor=actor["account_id"], version=version,
        before=encode(before), after=encode(after), note=note)
