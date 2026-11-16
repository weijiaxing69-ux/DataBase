from ...core.database import all_rows, execute, one
from ...core.errors import require


def confirmation_side(db, actor, operator_id):
    if "platform_admin" in actor["roles"]:
        return "platform"
    require("operator_manager" in actor["roles"] and
            "settlement.settlement.confirm" in actor["permissions"],
            403, "FORBIDDEN", "需要平台管理员或有确认权限的运营商。")
    require(one(db, """SELECT 1 FROM sys_account_operator
        WHERE account_id=:actor AND operator_id=:operator""",
        actor=actor["account_id"], operator=operator_id),
        403, "OUT_OF_SCOPE", "不能确认其他运营商的记录。")
    return "operator"


def add_confirmation(db, actor, side, kind, target, request):
    column = {"settlement": "settlement_id", "difference": "difference_id"}[kind]
    args = dict(target=target, version=request.object_version, side=side)
    execute(db, f"""UPDATE reconciliation_confirmation SET is_current=0
        WHERE {column}=:target AND object_version=:version AND side=:side AND is_current=1""", **args)
    result = execute(db, f"""INSERT INTO reconciliation_confirmation
        ({column},object_version,side,decision,confirmed_by,confirmed_at,note)
        VALUES(:target,:version,:side,:decision,:actor,UTC_TIMESTAMP(3),:note)""",
        **args, decision=request.decision, actor=actor["account_id"], note=request.note)
    accepted = one(db, f"""SELECT COUNT(*) AS n FROM reconciliation_confirmation
        WHERE {column}=:target AND object_version=:version AND is_current=1
          AND decision='confirmed'""", **args)["n"] == 2
    detail = one(db, f"""SELECT confirmation_id, {column} AS object_id, :kind AS object_type,
        object_version,side,decision,confirmed_by,confirmed_at,note FROM reconciliation_confirmation
        WHERE confirmation_id=:id""", kind=kind, id=result.lastrowid)
    return detail, accepted


def insert_difference(db, settlement_id, order_id, kind, amount):
    result = execute(db, """INSERT INTO reconciliation_difference
        (settlement_id,order_id,difference_type,amount)
        VALUES(:settlement,:order,:kind,:amount)""",
        settlement=settlement_id, order=order_id, kind=kind, amount=amount)
    return difference_row(db, result.lastrowid)


def difference_row(db, difference_id, lock=False):
    row = one(db, "SELECT * FROM reconciliation_difference WHERE difference_id=:id" +
              (" FOR UPDATE" if lock else ""), id=difference_id)
    require(row is not None, 404, "DIFFERENCE_NOT_FOUND", "差异记录不存在。")
    return row


def get_difference(db, *, actor, difference_id):
    from .service import get_settlement
    row = difference_row(db, difference_id)
    get_settlement(db, actor=actor, settlement_id=row["settlement_id"])
    return row


def create_difference(db, *, actor, request):
    from .service import locked_settlement
    require("customer_service" in actor["roles"], 403, "FORBIDDEN", "仅客服可创建差异单。")
    bill = locked_settlement(db, request.settlement_id)
    order = one(db, """SELECT operator_id,station_id,settlement_id FROM charging_order
        WHERE order_id=:id""", id=request.order_id)
    require(order and (order["operator_id"], order["station_id"]) ==
            (bill["operator_id"], bill["station_id"]) and
            order["settlement_id"] in (None, bill["settlement_id"]),
            422, "INVALID_DIFFERENCE_ORDER", "来源订单不属于该结算范围。")
    return insert_difference(db, request.settlement_id, request.order_id,
                             request.difference_type, request.amount)


def resolve_difference(db, *, actor, difference_id, request):
    require("customer_service" in actor["roles"], 403, "FORBIDDEN", "仅客服可处理差异。")
    row = difference_row(db, difference_id, lock=True)
    require(row["version"] == request.object_version, 409, "STALE_VERSION", "差异版本已变化。")
    require(row["status"] != "effective", 409, "INVALID_STATUS", "生效差异不得覆盖。")
    require(bool(request.resolution), 422, "RESOLUTION_REQUIRED", "请填写处理结论。")
    execute(db, """UPDATE reconciliation_difference SET resolution=:resolution,
        version=version+1,status='pending_confirmation' WHERE difference_id=:id""",
        resolution=request.resolution, id=difference_id)
    return difference_row(db, difference_id)


def confirm_difference(db, *, actor, difference_id, request):
    from .service import locked_settlement
    row = difference_row(db, difference_id)
    bill = locked_settlement(db, row["settlement_id"])
    row = difference_row(db, difference_id, lock=True)
    side = confirmation_side(db, actor, bill["operator_id"])
    require(row["version"] == request.object_version, 409, "STALE_VERSION", "差异版本已变化。")
    require(row["status"] == "pending_confirmation", 409, "INVALID_STATUS", "请先提交当前处理结论。")
    detail, accepted = add_confirmation(db, actor, side, "difference", difference_id, request)
    if accepted or request.decision == "disputed":
        execute(db, "UPDATE reconciliation_difference SET status=:status WHERE difference_id=:id",
                status="effective" if accepted else "rejected", id=difference_id)
    return detail


def adjust_settlement(db, *, actor, settlement_id, request):
    from .service import locked_settlement, scope
    scope(db, actor, write=True)
    bill = locked_settlement(db, settlement_id)
    require(bill["status"] != "closed" and request.amount != 0, 409,
            "INVALID_ADJUSTMENT", "已关闭结算单或零金额不能申请调整。")
    if request.difference_id is not None:
        difference = difference_row(db, request.difference_id, lock=True)
        require(difference["settlement_id"] == settlement_id and difference["status"] == "effective",
                409, "INVALID_ADJUSTMENT_DIFFERENCE", "须关联本结算单已生效的差异。")
        require(not one(db, """SELECT 1 FROM settlement_adjustment
            WHERE difference_id=:id AND status IN ('pending','approved')""", id=request.difference_id),
            409, "DUPLICATE_ADJUSTMENT", "该差异已有待审批或已批准的调整。")
    result = execute(db, """INSERT INTO settlement_adjustment
        (settlement_id,difference_id,amount,reason,requested_by)
        VALUES(:id,:difference_id,:amount,:reason,:actor)""",
        id=settlement_id, actor=actor["account_id"], **request.model_dump())
    return one(db, "SELECT * FROM settlement_adjustment WHERE adjustment_id=:id", id=result.lastrowid)


def review_settlement_adjustment(db, *, actor, adjustment_id, request):
    from .service import get_settlement, locked_settlement
    require("platform_admin" in actor["roles"], 403, "FORBIDDEN", "仅平台管理员可审批调整。")
    sql = "SELECT * FROM settlement_adjustment WHERE adjustment_id=:id"
    row = one(db, sql, id=adjustment_id)
    require(row, 404, "ADJUSTMENT_NOT_FOUND", "调整申请不存在。")
    bill = locked_settlement(db, row["settlement_id"])
    row = one(db, sql + " FOR UPDATE", id=adjustment_id)
    require(row["requested_by"] != actor["account_id"], 403, "SELF_APPROVAL", "申请人不得自批。")
    require(row["status"] == "pending" and bill["status"] != "closed", 409,
            "INVALID_STATUS", "当前申请不可审批。")
    if request.decision == "approved":
        net = one(db, """SELECT COALESCE(SUM(IF(invoice_type='blue',amount,-amount)),0) AS n
            FROM operator_invoice WHERE settlement_id=:id FOR UPDATE""", id=bill["settlement_id"])["n"]
        due = bill["payable_amount"] + row["amount"]
        require(due >= net, 409, "ADJUSTMENT_BELOW_INVOICED", "调整后应结金额不足，请先核对或红冲。")
        execute(db, """UPDATE operator_settlement SET adjustment_amount=adjustment_amount+:amount,
            payable_amount=:due,version=version+1,status='pending_confirmation'
            WHERE settlement_id=:id""", amount=row["amount"], due=due, id=bill["settlement_id"])
    execute(db, """UPDATE settlement_adjustment SET status=:decision,approved_by=:actor,
        approved_at=UTC_TIMESTAMP(3) WHERE adjustment_id=:id""",
        id=adjustment_id, actor=actor["account_id"], decision=request.decision)
    return get_settlement(db, actor=actor, settlement_id=bill["settlement_id"])
