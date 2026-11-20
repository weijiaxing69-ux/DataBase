"""Run with python backend/tests/settlement/test_flow.py from the project root."""

from pathlib import Path
from secrets import token_urlsafe
import tempfile
from uuid import uuid4

from support import ROOT, Instance, TestClient, create_app, find_bin, install_settlement_sql


def verify(db):
    db.query("""
        DELETE FROM sys_account_operator WHERE account_id=106 AND operator_id<>1;
        INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,
          status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,
          discount_amount,payable_amount)
        VALUES(1,1,1,1,1,'personal','paid','2026-11-12 13:30:00','2026-11-12 14:30:00',
          10,6.40,2.60,3.00,6.00);
        INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
        VALUES(LAST_INSERT_ID(),'mock','MEMBER5-FLOW',6,'succeeded','2026-11-12 14:35:00');
    """).check_returncode()
    app = create_app(f"mysql+pymysql://root@127.0.0.1:{db.port}/charging_platform_test?charset=utf8mb4",
                     token_urlsafe(48))
    with TestClient(app) as client:
        base = "/api/v1/settlement"

        def login(username):
            result = client.post("/api/v1/auth/login", json={"username": username,
                                                          "password": "ChargeDemo-2026!"})
            assert result.status_code == 200, result.text
            return {"Authorization": "Bearer " + result.json()["access_token"]}

        admin = login("platform_admin_demo")
        operator = login("operator_manager_demo")
        assert client.get(base + "/settlements").status_code == 401
        assert client.get(base + "/settlements?bill_month=2026-10-01&page_size=5", headers=admin).json()["total"] == 20
        assert client.get(base + "/settlements/2", headers=operator).status_code == 403
        assert client.get(base + "/settlements", headers=operator).json()["total"] == 1

        def post(path, data, headers=admin, key=None):
            return client.post(base + path, json=data, headers={
                **headers, "Idempotency-Key": key or uuid4().hex,
            })

        generated = post("/settlements", dict(operator_id="1", station_id="1", bill_month="2026-11-01"))
        assert generated.status_code == 201, generated.text
        bill = generated.json()
        assert bill["status"] == "pending_confirmation" and bill["payable_amount"] == "4.07", bill
        path = "/settlements/" + bill["settlement_id"]
        issue = dict(title="演示运营商", tax_no="DEMO", amount="4.07")
        confirmation = dict(object_version=1, decision="confirmed")
        assert post(path + "/confirmations", {**confirmation, "object_version": 2}).status_code == 409
        assert post(path + "/confirmations", confirmation).json()["side"] == "platform"
        blocked = post(path + "/invoices", issue)
        assert blocked.status_code == 409 and blocked.json()["code"] == "SETTLEMENT_CONFIRMATION_REQUIRED", blocked.text
        assert client.get(base + "/operator-invoices?settlement_id=" + bill["settlement_id"], headers=admin).json()["total"] == 0
        assert post(path + "/confirmations", confirmation, operator).json()["side"] == "operator"
        assert post(path + "/invoices", issue, operator).status_code == 403
        key = uuid4().hex
        opened = post(path + "/invoices", issue, key=key)
        assert opened.status_code == 201, opened.text
        assert post(path + "/invoices", issue, key=key).json() == opened.json()
        assert post(path + "/invoices", {**issue, "amount": "0.01"}, key=key).json()["code"] == "IDEMPOTENCY_CONFLICT"
        assert post(path + "/invoices", {**issue, "amount": "0.01"}).json()["code"] == "INVOICE_EXCEEDS_SETTLEMENT"
        invoice = opened.json()
        red_path = "/operator-invoices/" + invoice["invoice_id"] + "/red-issues"
        assert post(red_path, dict(amount="4.08", reason="超出原票")).json()["code"] == "RED_INVOICE_EXCEEDS_ORIGINAL"
        assert post(red_path, dict(amount="1.07", reason="演示红冲")).status_code == 200
        final = client.get(base + path, headers=admin).json()
        assert final["status"] == "invoiced" and final["net_issued_amount"] == "3.00", final
        assert client.post("/api/v1/auth/logout", headers=admin).status_code == 204
        assert client.get(base + path, headers=admin).status_code == 401


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="settlement-api-") as directory:
        instance = Instance(find_bin(None), Path(directory))
        try:
            instance.start()
            install_settlement_sql(instance)
            verify(instance)
            print("PASS: login, pagination, operator scope, generation, two-party confirmation, invoice, idempotency and red issue.")
        finally:
            instance.close()
