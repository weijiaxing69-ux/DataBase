"""Verify the member-five SQL against the shared V1.4 fixtures."""

from pathlib import Path
import sys
import tempfile

sys.dont_write_bytecode = True
MODULE = Path(__file__).resolve().parent
sys.path.insert(0, str(MODULE.parents[2] / "新能源项目最新版_V1.4"))

from test_mysql_v14 import Instance, expect, find_bin, rejected, transaction


def verify(db):
    db.start()
    db.load()
    for filename in ("05_views.sql", "06_procedures.sql", "07_triggers.sql"):
        db.query((MODULE / filename).read_text(encoding="utf-8")).check_returncode()

    for view in ("v_settlement_summary", "v_reconciliation_difference_status", "v_fleet_bill_receipts"):
        expect(db.query(f"SELECT COUNT(*) FROM {view}"), "20")
    result = db.query((MODULE / "08_queries.sql").read_text(encoding="utf-8"))
    result.check_returncode()
    rows = result.stdout.splitlines()
    if len(rows) != 120 or any(rows[i:i + 20] != rows[i + 20:i + 40] for i in (0, 40, 80)):
        raise AssertionError("The two implementations of each query must return the same 20 rows.")

    def call(settlement, number, original, amount):
        return (f"CALL sp_settlement_issue_operator_invoice({settlement},'{number}',"
                f"{original},'测试抬头','DEMO', {amount},103)")

    rejected(transaction(db, call(1, "TEST-LIMIT", "NULL", "0.01")),
             1644, "INVOICE_EXCEEDS_SETTLEMENT")
    rejected(transaction(db, call(2, "TEST-WRONG-ORIGINAL", "1", "0.20")),
             1644, "RED_INVOICE_INVALID_ORIGINAL")
    rejected(transaction(db, call(1, "TEST-OVER-RED", "1", "9999")),
             1644, "RED_INVOICE_EXCEEDS_ORIGINAL")
    rejected(transaction(db, "UPDATE operator_settlement SET version=3 WHERE settlement_id=1",
                         call(1, "TEST-RED", "1", "0.20"),
                         call(1, "TEST-OLD-VERSION", "NULL", "0.20")),
             1644, "SETTLEMENT_CONFIRMATION_REQUIRED")

    create = """INSERT INTO operator_settlement
        (settlement_id, operator_id, station_id, bill_month, payable_amount, status)
        VALUES (999999,1,1,'2026-11-01',10,'confirmed')"""
    platform = """INSERT INTO reconciliation_confirmation
        (settlement_id,object_version,side,decision,confirmed_by,confirmed_at)
        VALUES (999999,1,'platform','confirmed',101,UTC_TIMESTAMP())"""
    operator = platform.replace("'platform','confirmed',101", "'operator','confirmed',106")
    issue = call(999999, "TEST-ISSUE", "NULL", "6.00")
    rejected(transaction(db, create, platform, issue),
             1644, "SETTLEMENT_CONFIRMATION_REQUIRED")
    result = transaction(
        db, create, platform, operator, issue,
        "SELECT status, net_issued_amount FROM v_settlement_summary WHERE settlement_id=999999",
    )
    result.check_returncode()
    if result.stdout.splitlines()[-1] != "invoiced\t6.00":
        raise AssertionError(result.stdout)
    expect(db.query("SELECT COUNT(*) FROM operator_settlement WHERE settlement_id=999999"), "0")

    result = transaction(
        db, call(1, "TEST-RED", "1", "0.20"), call(1, "TEST-REISSUE", "NULL", "0.20"),
        "SELECT payable_amount = net_issued_amount FROM v_settlement_summary WHERE settlement_id=1",
    )
    result.check_returncode()
    if result.stdout.splitlines()[-1] != "1":
        raise AssertionError(result.stdout)


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="codex-settlement-v14-") as temp:
        instance = Instance(find_bin(None), Path(temp))
        try:
            verify(instance)
            print("PASS: views, equivalent query pairs, invoice guards, red issue and rollback.")
        finally:
            instance.close()
