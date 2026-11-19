"""Real MySQL contention and history tests. Run directly from the project root."""
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from decimal import Decimal
from pathlib import Path
from secrets import token_urlsafe
from threading import Barrier
import tempfile

from test_flow import Instance, TestClient, create_app, find_bin, install_settlement_sql
from sqlalchemy import event, text
from sqlalchemy.orm import Session
from pymysql.err import MySQLError
from app.core.auth import account_context
from app.core.errors import BusinessError
from app.modules.settlement import schemas, service


def verify(engine):
    with engine.connect() as connection:
        print("MySQL:", connection.exec_driver_sql("SELECT VERSION()").scalar_one(), flush=True)
    with Session(engine) as db:
        actors = {name: account_context(db, aid) for name, aid in
                  (("admin", 101), ("staff", 103), ("operator", 106))}

    def query(sql, **params):
        with engine.connect() as db:
            return [dict(r) for r in db.execute(text(sql), params).mappings()]

    def invoke(fn, **params):
        with Session(engine) as db, db.begin():
            return fn(db, **params)

    def race(*jobs, raw_procedure=False):
        # Separate sessions/connections reach the SAME parent-row locking statement
        # together, rather than merely executing two sequential requests.
        gate = Barrier(len(jobs), timeout=15)
        connections = set()

        def run(job):
            with engine.connect() as connection:
                connection_id = connection.exec_driver_sql("SELECT CONNECTION_ID()").scalar_one()
                connection.rollback()
                connections.add(connection_id)
                waited = False

                def synchronize(conn, cursor, statement, parameters, context, executemany):
                    nonlocal waited
                    if not waited and "FOR UPDATE" in statement.upper():
                        waited = True
                        gate.wait()

                event.listen(connection, "before_cursor_execute", synchronize)
                try:
                    with Session(bind=connection) as db, db.begin():
                        if raw_procedure:
                            # CALL uses a raw DBAPI cursor, outside SQLAlchemy events.
                            # Start both real procedures together; add no test-only locks.
                            waited = True
                            gate.wait()
                        value = job(db)
                    return ("ok", value)
                except BusinessError as exc:
                    return ("rejected", exc.code)
                except MySQLError as exc:
                    if exc.args[0] != 1644:
                        raise
                    return ("rejected", exc.args[1])
                finally:
                    event.remove(connection, "before_cursor_execute", synchronize)

        with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
            results = list(pool.map(run, jobs))
        assert len(connections) == len(jobs), connections
        return results

    def one_winner(results, code):
        assert sum(r[0] == "ok" for r in results) == 1, results
        assert [r[1] for r in results if r[0] == "rejected"] == [code], results

    def confirm(sid, version, who):
        return invoke(service.confirm_settlement, actor=actors[who], settlement_id=sid,
                      request=schemas.ConfirmationRequest(object_version=version, decision="confirmed"))

    with engine.begin() as db:
        db.execute(text("""INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,
            order_mode,status,started_at,finished_at,energy_kwh,electricity_amount,
            service_amount,discount_amount,payable_amount)
            VALUES(1,1,1,1,1,'personal','paid','2026-11-12 13:30:00','2026-11-12 14:30:00',
            10,6.40,2.60,3.00,6.00)"""))
        oid = db.execute(text("SELECT LAST_INSERT_ID()")).scalar_one()
        db.execute(text("""INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
            VALUES(:oid,'mock','CONCURRENCY-ORDER',6,'succeeded','2026-11-12 14:35:00')"""), {"oid": oid})

    request = schemas.GenerateSettlementRequest(operator_id=1, station_id=1, bill_month=date(2026, 11, 1))
    results = race(*(lambda db: service.generate_settlement(db, actor=actors["admin"], request=request)
                     for _ in range(2)))
    one_winner(results, "SETTLEMENT_EXISTS")
    bill = next(r[1] for r in results if r[0] == "ok")
    sid = bill["settlement_id"]
    assert len(query("SELECT * FROM operator_settlement WHERE operator_id=1 AND station_id=1 AND bill_month='2026-11-01'")) == 1
    assert len(query("SELECT * FROM settlement_item WHERE order_id=:id AND item_type='order'", id=oid)) == 1
    assert query("SELECT settlement_id FROM charging_order WHERE order_id=:id", id=oid)[0]["settlement_id"] == sid
    print("PASS C01: concurrent month generation: one bill, one original-order item.")

    for who in ("admin", "operator"):
        confirm(sid, 1, who)
    issue = schemas.IssueOperatorInvoiceRequest(title="Concurrency", tax_no="DEMO", amount=Decimal("3.00"))
    results = race(*(lambda db: service.issue_operator_invoice(db, actor=actors["admin"],
                     settlement_id=sid, request=issue) for _ in range(2)), raw_procedure=True)
    one_winner(results, "INVOICE_EXCEEDS_SETTLEMENT")
    original = next(r[1] for r in results if r[0] == "ok")
    invoices = query("SELECT * FROM operator_invoice WHERE settlement_id=:id", id=sid)
    assert len(invoices) == 1 and invoices[0]["amount"] == Decimal("3.00")
    print("PASS C02: concurrent blue invoices: cumulative cap and failed-write rollback.")

    red = schemas.RedIssueInvoiceRequest(amount=Decimal("2.00"), reason="Concurrent partial red")
    results = race(*(lambda db: service.red_issue_operator_invoice(db, actor=actors["admin"],
                     invoice_id=original["invoice_id"], request=red) for _ in range(2)), raw_procedure=True)
    one_winner(results, "RED_INVOICE_EXCEEDS_ORIGINAL")
    invoices = query("SELECT * FROM operator_invoice WHERE settlement_id=:id", id=sid)
    assert len(invoices) == 2
    assert sum(i["amount"] if i["invoice_type"] == "blue" else -i["amount"] for i in invoices) == Decimal("1.00")
    print("PASS C03: concurrent red invoices: original balance protected, one red record.")

    difference = invoke(service.create_difference, actor=actors["staff"],
        request=schemas.CreateDifferenceRequest(settlement_id=sid, order_id=oid, difference_type="price", amount="0.50"))
    did = difference["difference_id"]
    for conclusion in ("first conclusion", "revised conclusion"):
        old = invoke(service.get_difference, actor=actors["staff"], difference_id=did)
        resolved = invoke(service.resolve_difference, actor=actors["staff"], difference_id=did,
            request=schemas.ResolveDifferenceRequest(object_version=old["version"], resolution=conclusion))
        invoke(service.confirm_difference, actor=actors["admin"], difference_id=did,
            request=schemas.ConfirmationRequest(object_version=resolved["version"], decision="confirmed", note=conclusion))
    history = query("SELECT * FROM reconciliation_confirmation WHERE difference_id=:id ORDER BY confirmation_id", id=did)
    assert [h["object_version"] for h in history] == [2, 3]
    assert [h["note"] for h in history] == ["first conclusion", "revised conclusion"]
    assert invoke(service.get_difference, actor=actors["admin"], difference_id=did)["status"] == "pending_confirmation"
    try:
        invoke(service.confirm_difference, actor=actors["operator"], difference_id=did,
            request=schemas.ConfirmationRequest(object_version=2, decision="confirmed"))
    except BusinessError as exc:
        assert exc.code == "STALE_VERSION"
    else:
        raise AssertionError("An old difference version was accepted")
    invoke(service.confirm_difference, actor=actors["operator"], difference_id=did,
        request=schemas.ConfirmationRequest(object_version=3, decision="confirmed"))
    assert invoke(service.get_difference, actor=actors["admin"], difference_id=did)["status"] == "effective"
    print("PASS C04: difference confirmation history retained; obsolete version cannot authorize revision.")

    # A second bill without invoices lets confirmation race against amount revision.
    with engine.begin() as db:
        db.execute(text("""INSERT INTO operator_settlement(operator_id,station_id,bill_month,payable_amount,status)
            VALUES(1,1,'2026-12-01',10,'pending_confirmation')"""))
        sid2 = db.execute(text("SELECT LAST_INSERT_ID()")).scalar_one()
    for who in ("admin", "operator"):
        confirm(sid2, 1, who)
    adjustment = invoke(service.adjust_settlement, actor=actors["staff"], settlement_id=sid2,
        request=schemas.AdjustSettlementRequest(amount="0.50", reason="Concurrency revision"))
    results = race(
        lambda db: service.confirm_settlement(db, actor=actors["operator"], settlement_id=sid2,
            request=schemas.ConfirmationRequest(object_version=1, decision="confirmed")),
        lambda db: service.review_settlement_adjustment(db, actor=actors["admin"],
            adjustment_id=adjustment["adjustment_id"],
            request=schemas.AdjustmentReviewRequest(decision="approved", note="Different reviewer")),
    )
    assert results[1][0] == "ok", results
    assert results[0][0] == "ok" or results[0] == ("rejected", "STALE_VERSION"), results
    row = invoke(service.get_settlement, actor=actors["admin"], settlement_id=sid2)
    assert row["version"] == 2 and row["payable_amount"] == Decimal("10.50")
    assert row["status"] == "pending_confirmation"
    assert row["platform_confirmation"] is None and row["operator_confirmation"] is None
    assert len(query("SELECT * FROM reconciliation_confirmation WHERE settlement_id=:id AND object_version=1", id=sid2)) >= 2
    try:
        invoke(service.issue_operator_invoice, actor=actors["admin"], settlement_id=sid2,
               request=schemas.IssueOperatorInvoiceRequest(title="Blocked", tax_no="DEMO", amount="1.00"))
    except Exception as exc:
        assert "SETTLEMENT_CONFIRMATION_REQUIRED" in str(exc), str(exc)
    else:
        raise AssertionError("Old confirmations authorized the new amount")
    assert not query("SELECT * FROM operator_invoice WHERE settlement_id=:id", id=sid2)
    print("PASS C05: confirmation versus adjustment: version 2 needs fresh two-party confirmation.")


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="settlement-concurrency-") as directory:
        instance = Instance(find_bin(None), Path(directory))
        try:
            instance.start()
            install_settlement_sql(instance)
            url = f"mysql+pymysql://root@127.0.0.1:{instance.port}/charging_platform_test?charset=utf8mb4"
            with TestClient(create_app(url, token_urlsafe(48))) as client:
                verify(client.app.state.engine)
            print("PASS: 5 real-MySQL concurrency/history cases; independent clients and rollback verified.")
        finally:
            instance.close()
