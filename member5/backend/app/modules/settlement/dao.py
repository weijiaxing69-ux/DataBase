from ...core.database import all_rows, one


def settlement_detail(db, settlement_id):
    row = one(db, """SELECT v.*, s.created_at, s.updated_at FROM v_settlement_summary v
        JOIN operator_settlement s USING(settlement_id) WHERE v.settlement_id=:id""", id=settlement_id)
    if row is None:
        return None
    confirmations = all_rows(db, """SELECT confirmation_id, settlement_id AS object_id,
        'settlement' AS object_type, object_version, side, decision, confirmed_by, confirmed_at, note
        FROM reconciliation_confirmation WHERE settlement_id=:id AND object_version=:version
        AND is_current=1""", id=settlement_id, version=row["version"])
    by_side = {c["side"]: c for c in confirmations}
    return {**row, "platform_confirmation": by_side.get("platform"),
            "operator_confirmation": by_side.get("operator"),
            "items": all_rows(db, "SELECT * FROM settlement_item WHERE settlement_id=:id ORDER BY settlement_item_id",
                              id=settlement_id)}


def invoice_procedure(db, settlement_id, number, original_id, title, tax_no, amount, actor_id):
    # Consume the trailing CALL result set before returning the connection to SQLAlchemy.
    with db.connection().connection.driver_connection.cursor() as cursor:
        cursor.execute("CALL sp_settlement_issue_operator_invoice(%s,%s,%s,%s,%s,%s,%s)",
                       (settlement_id, number, original_id, title, tax_no, amount, actor_id))
        invoice_id = cursor.fetchone()[0]
        while cursor.nextset():
            pass
    return one(db, "SELECT * FROM operator_invoice WHERE invoice_id=:id", id=invoice_id)
