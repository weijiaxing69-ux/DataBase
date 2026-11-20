from datetime import timezone

from ...core.database import all_rows, execute, one
from ...core.errors import require


def utc(value):
    return value.astimezone(timezone.utc).replace(tzinfo=None) if value.tzinfo else value


def page(db, query, source, key, fields=(), keywords=(), time="created_at", scope=None, order=None):
    conditions, params = [], {}
    if scope:
        conditions.append(scope[0])
        params.update(scope[1])
    for field in fields:
        value = getattr(query, field, None)
        if value is not None:
            conditions.append(f"v.{field}=:{field}")
            params[field] = value
    if query.keyword and keywords:
        conditions.append("(" + " OR ".join(f"LOCATE(:keyword,{col})>0" for col in keywords) + ")")
        params["keyword"] = query.keyword
    for name, op in (("start_at", ">="), ("end_at", "<")):
        value = getattr(query, name)
        if value:
            conditions.append(f"v.{time}{op}:{name}")
            params[name] = utc(value)
    require(not (query.start_at and query.end_at) or params["start_at"] < params["end_at"],
            422, "INVALID_PERIOD", "开始时间须早于结束时间。")
    where = " WHERE " + " AND ".join(conditions) if conditions else ""
    total = one(db, f"SELECT COUNT(*) AS n FROM {source}{where}", **params)["n"]
    sort = order or f"v.{key} DESC"
    items = all_rows(db, f"SELECT v.* FROM {source}{where} ORDER BY {sort} LIMIT :lim OFFSET :off",
                     **params, lim=query.page_size, off=(query.page-1)*query.page_size)
    return dict(items=items, total=total, page=query.page, page_size=query.page_size)


def operator_scope(db, actor, column):
    from .service import scope
    if scope(db, actor) is not None:
        return (f"EXISTS (SELECT 1 FROM sys_account_operator a WHERE a.operator_id={column}"
                " AND a.account_id=:actor)", {"actor": actor["account_id"]})


def list_settlements(db, *, actor, query):
    from .service import get_settlement
    result = page(db, query, "operator_settlement v JOIN operator o USING(operator_id)"
                  " JOIN station s ON s.station_id=v.station_id", "settlement_id",
                  ("operator_id", "station_id", "bill_month", "status"),
                  ("o.operator_name", "s.station_name", "v.settlement_id"),
                  scope=operator_scope(db, actor, "v.operator_id"), order="v.bill_month DESC,v.settlement_id")
    result["items"] = [get_settlement(db, actor=actor, settlement_id=x["settlement_id"])
                       for x in result["items"]]
    return result


def list_differences(db, *, actor, query):
    return page(db, query, "reconciliation_difference v JOIN operator_settlement s USING(settlement_id)",
                "difference_id", ("settlement_id", "status"), ("v.order_id", "v.resolution", "v.difference_type"),
                scope=operator_scope(db, actor, "s.operator_id"))


def list_operator_invoices(db, *, actor, query):
    return page(db, query, "operator_invoice v JOIN operator_settlement s USING(settlement_id)",
                "invoice_id", ("settlement_id",), ("v.invoice_no", "v.title"), "issued_at",
                operator_scope(db, actor, "s.operator_id"))


def get_operator_invoice(db, *, actor, invoice_id):
    from .service import scope
    row = one(db, """SELECT i.*,s.operator_id FROM operator_invoice i JOIN operator_settlement s
        USING(settlement_id) WHERE invoice_id=:id""", id=invoice_id)
    require(row, 404, "INVOICE_NOT_FOUND", "发票不存在。")
    scope(db, actor, row.pop("operator_id"))
    return row


def admin(actor):
    require("platform_admin" in actor["roles"], 403, "FORBIDDEN", "仅平台管理员可管理分成政策。")


def list_settlement_policies(db, *, actor, query):
    admin(actor)
    return page(db, query, "settlement_policy v JOIN operator o USING(operator_id)"
                " JOIN station s ON s.station_id=v.station_id", "policy_id",
                ("operator_id", "station_id"), ("o.operator_name", "s.station_name"), "valid_from")


def get_settlement_policy(db, *, actor, policy_id):
    admin(actor)
    row = one(db, "SELECT * FROM settlement_policy WHERE policy_id=:id", id=policy_id)
    require(row, 404, "POLICY_NOT_FOUND", "分成政策不存在。")
    return row


def create_settlement_policy(db, *, actor, request):
    admin(actor)
    args = request.model_dump()
    for name in ("valid_from", "valid_until"):
        args[name] = utc(args[name])
    require(args["valid_from"] < args["valid_until"], 422, "INVALID_PERIOD", "生效时间须早于失效时间。")
    require(request.platform_fee_rate <= min(request.electricity_share_rate, request.service_share_rate),
            422, "INVALID_SHARE_RATES", "平台费比例不能超过任一分成比例。")
    station = one(db, "SELECT operator_id FROM station WHERE station_id=:station_id FOR UPDATE", **args)
    require(station and station["operator_id"] == request.operator_id,
            422, "INVALID_STATION_OPERATOR", "场站和运营商不匹配。")
    require(not one(db, """SELECT policy_id FROM settlement_policy
        WHERE operator_id=:operator_id AND station_id=:station_id
        AND valid_from<:valid_until AND valid_until>:valid_from LIMIT 1 FOR UPDATE""", **args),
        409, "POLICY_OVERLAP", "相同场站的分成政策有效期不能重叠。")
    result = execute(db, """INSERT INTO settlement_policy(operator_id,station_id,electricity_share_rate,
        service_share_rate,platform_fee_rate,payment_basis,valid_from,valid_until)
        VALUES(:operator_id,:station_id,:electricity_share_rate,:service_share_rate,:platform_fee_rate,
        :payment_basis,:valid_from,:valid_until)""", **args)
    return get_settlement_policy(db, actor=actor, policy_id=result.lastrowid)


def list_adjustments(db, *, actor, query):
    return page(db, query, "settlement_adjustment v JOIN operator_settlement s USING(settlement_id)",
                "adjustment_id", ("settlement_id", "status"), ("v.reason", "v.adjustment_id"),
                scope=operator_scope(db, actor, "s.operator_id"))


def get_adjustment(db, *, actor, adjustment_id):
    from .service import get_settlement
    row = one(db, "SELECT * FROM settlement_adjustment WHERE adjustment_id=:id", id=adjustment_id)
    require(row, 404, "ADJUSTMENT_NOT_FOUND", "调整申请不存在。")
    get_settlement(db, actor=actor, settlement_id=row["settlement_id"])
    return row


def list_audit_events(db, *, actor, query):
    from . import service
    readers = {
        "settlement": (service.get_settlement, "settlement_id"),
        "difference": (service.get_difference, "difference_id"),
        "adjustment": (get_adjustment, "adjustment_id"),
        "operator_invoice": (get_operator_invoice, "invoice_id"),
        "user_invoice": (service.get_user_invoice, "user_invoice_id"),
    }
    reader, key = readers[query.object_type]
    reader(db, actor=actor, **{key: query.object_id})
    result = page(db, query, "settlement_audit_event v", "event_id", ("object_type", "object_id"),
                  ("v.action", "v.note"))
    import json
    for row in result["items"]:
        for name in ("before_state", "after_state"):
            if isinstance(row[name], str):
                row[name] = json.loads(row[name])
    return result
