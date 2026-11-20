"""Run the V1.4 settlement acceptance cases in an isolated MySQL instance."""
import json
import inspect
import re
from pathlib import Path
from secrets import token_urlsafe
import tempfile
from datetime import datetime
from decimal import Decimal
from uuid import uuid4
from sqlalchemy.orm import Session

from support import ROOT, Instance, TestClient, create_app, find_bin, install_settlement_sql


def contract(client):
    from app.modules.settlement import pricing, service
    spec = next((ROOT / "新能源项目最新版_V1.4").glob("*接口函数规范*.json"))
    data = json.loads(spec.read_text(encoding="utf-8-sig"))
    declared = {(a["method"].lower(), a["path"]) for a in data["api"] if a["module"] == "settlement"}
    actual = {(method, path) for path, item in client.get("/openapi.json").json()["paths"].items()
              if path.startswith("/api/v1/settlement/") for method in item}
    extensions = {("get", "/api/v1/settlement"+p) for p in
                  ("/adjustments", "/adjustments/{adjustment_id}", "/audit-events")}
    assert actual == declared | extensions, (declared - actual, actual - declared - extensions)
    for item in data["functions"]:
        if item["module"] == "settlement":
            module = pricing if item["file"] == "pricing.py" else service
            actual_args = inspect.signature(getattr(module, item["name"])).parameters
            expected = [arg.split(":")[0] for arg in item["args"] if arg != "*"]
            assert list(actual_args) == expected, item["name"]
            assert all(actual_args[arg].kind == inspect.Parameter.KEYWORD_ONLY for arg in expected[1:])
    for route in data["pages"]:
        if route["module"] == "settlement":
            path = re.sub(r":\w+", "1", route["path"])
            assert client.get(path).status_code == 200, path


def seed(db):
    result = db.query("""
        UPDATE app_user SET account_id=104 WHERE user_id=1;
        DELETE FROM sys_account_fleet WHERE account_id=105 AND fleet_id<>1;
        INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,
            status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,discount_amount,payable_amount)
        SELECT u.user_id,1,1,1,1,'personal','paid','2026-11-02 13:30:00','2026-11-02 14:30:00',
            10,6.40,2.60,3.00,6.00 FROM app_user u WHERE u.account_id=104;
        SET @paid=LAST_INSERT_ID();
        INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
            VALUES(@paid,'mock','V14-PAID',6,'succeeded','2026-11-02 14:35:00');
        INSERT INTO refund_record(payment_id,external_refund_no,amount,status,refunded_at,reason,requested_by)
            VALUES(LAST_INSERT_ID(),'V14-REFUND',1.00,'succeeded','2026-12-05','V14 test',103);
        INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,
            status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,discount_amount,payable_amount)
        SELECT u.user_id,1,1,1,1,'personal','awaiting_payment','2026-11-03 13:30:00','2026-11-03 14:30:00',
            10,6.40,2.60,3.00,6.00 FROM app_user u WHERE u.account_id=104;
        SET @unpaid=LAST_INSERT_ID();
        INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,
            fleet_id,order_mode,status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,payable_amount)
        SELECT user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,
            fleet_id,'fleet','awaiting_payment','2026-11-04 13:30:00','2026-11-04 14:30:00',10,8,2,10
        FROM charging_order WHERE fleet_id=1 AND order_mode='fleet' LIMIT 1;
        SELECT @paid,@unpaid,LAST_INSERT_ID();
    """)
    assert not result.returncode, result.stderr
    return result.stdout.strip().splitlines()[-1].split("\t")


def verify(db, client):
    base = "/api/v1/settlement"
    paid_order, unpaid_order, fleet_order = seed(db)

    def login(name):
        r = client.post("/api/v1/auth/login", json={"username": name+"_demo", "password": "ChargeDemo-2026!"})
        assert r.status_code == 200, r.text
        return {"Authorization": "Bearer " + r.json()["access_token"]}

    admin, staff, operator, owner, fleet = map(login, (
        "platform_admin", "customer_service", "operator_manager", "vehicle_owner", "fleet_admin"))

    def get(path, actor, expected=200):
        r = client.get(base+path, headers=actor)
        assert r.status_code == expected, (path, r.text)
        return r.json()

    def post(path, data, actor, expected=200, key=None):
        r = client.post(base+path, json=data, headers={**actor, "Idempotency-Key": key or uuid4().hex})
        assert r.status_code == expected, (path, r.status_code, r.text)
        return r.json()

    policy = dict(operator_id="1", station_id="1", electricity_share_rate="0.7",
                  service_share_rate="0.7", platform_fee_rate="0.05", payment_basis="paid_only",
                  valid_from="2031-01-01T00:00:00Z", valid_until="2032-01-01T00:00:00Z")
    pid = post("/policies", policy, admin, 201)["policy_id"]
    assert get("/policies/"+pid, admin)["payment_basis"] == "paid_only"
    assert post("/policies", policy, admin, 409)["code"] == "POLICY_OVERLAP"
    get("/policies", operator, 403)

    bill = post("/settlements", dict(operator_id="1", station_id="1", bill_month="2026-11-01"), admin, 201)
    sid = bill["settlement_id"]
    assert bill["payable_amount"] == "4.07" and bill["items"][0]["order_id"] == paid_order
    todo = get("/differences?settlement_id="+sid, staff)["items"]
    assert {row["order_id"]: row["amount"] for row in todo} == {unpaid_order: "6.00", fleet_order: "10.00"}, todo
    assert post("/differences", dict(settlement_id=sid, order_id=paid_order, difference_type="price", amount="0.50"),
                admin, 403)["code"] == "FORBIDDEN"
    diff = post("/differences", dict(settlement_id=sid, order_id=paid_order, difference_type="price",
                amount="0.50"), staff, 201)
    dp = "/differences/"+diff["difference_id"]
    resolved = post(dp+"/resolutions", dict(resolution="verified", object_version=1), staff)
    post(dp+"/confirmations", dict(object_version=1, decision="confirmed"), admin, 409)
    decision = dict(object_version=resolved["version"], decision="confirmed")
    post(dp+"/confirmations", decision, admin)
    assert get(dp, admin)["status"] == "pending_confirmation"
    post(dp+"/confirmations", decision, operator)
    assert get(dp, admin)["status"] == "effective"

    for actor in (admin, operator):
        post(f"/settlements/{sid}/confirmations", dict(object_version=1, decision="confirmed"), actor)
    own = post(f"/settlements/{sid}/adjustments", dict(amount="0.50", reason="self approval case"), admin, 201)
    review = dict(decision="approved", note="verified")
    assert post(f"/adjustments/{own['adjustment_id']}/reviews", review, admin, 403)["code"] == "SELF_APPROVAL"
    adj = post(f"/settlements/{sid}/adjustments",
               dict(amount="0.50", reason="approved difference", difference_id=diff["difference_id"]), staff, 201)
    revised = post(f"/adjustments/{adj['adjustment_id']}/reviews", review, admin)
    assert revised["version"] == 2 and revised["payable_amount"] == "4.57"
    assert revised["platform_confirmation"] is None and revised["operator_confirmation"] is None
    post(f"/settlements/{sid}/invoices", dict(title="Demo", tax_no="DEMO", amount="4.57"), admin, 409)
    for actor in (admin, operator):
        post(f"/settlements/{sid}/confirmations", dict(object_version=2, decision="confirmed"), actor)
    ticket = post(f"/settlements/{sid}/invoices", dict(title="Demo", tax_no="DEMO", amount="4.57"), admin, 201)
    assert get("/operator-invoices?keyword="+ticket["invoice_no"], admin)["total"] == 1

    ri = "/user-invoices"
    request = dict(title="Owner", items=[dict(order_id=paid_order, allocated_amount="5.00")])
    invoice = post(ri, request, owner, 201)
    iid = invoice["user_invoice_id"]
    post(ri, request, owner, 409)
    post(f"{ri}/{iid}/processing", dict(decision="issued"), owner, 403)
    assert post(f"{ri}/{iid}/processing", dict(decision="issued"), staff)["status"] == "issued"
    assert post(f"{ri}/{iid}/red-issues", dict(amount="2.00", reason="partial refund"), staff)["amount"] == "2.00"
    post(f"{ri}/{iid}/red-issues", dict(amount="3.01", reason="too much"), staff, 409)
    assert get(f"{ri}/{iid}", owner)["status"] == "issued"
    post(ri, dict(title="Owner", items=[dict(order_id=paid_order, allocated_amount="2.00")]), owner, 201)
    from app.core.errors import BusinessError
    from app.modules.settlement.service import assert_order_invoice_refundable
    with Session(client.app.state.engine) as session, session.begin():
        try:
            assert_order_invoice_refundable(session, order_id=int(paid_order), refund_amount=Decimal("0.01"))
        except BusinessError as error:
            assert error.code == "USER_INVOICE_RED_ISSUE_REQUIRED"
        else:
            raise AssertionError("Refund exceeding the unallocated balance was allowed")

    price = post("/fleet-prices", dict(fleet_id="1", period_id="11", electricity_rate="0.4",
                 service_rate="0.1", valid_from="2031-01-01T00:00:00Z",
                 valid_until="2032-01-01T00:00:00Z"), admin, 201)
    assert price["status"] == "draft"
    from app.modules.settlement.pricing import get_fleet_price
    with Session(client.app.state.engine) as session:
        assert get_fleet_price(session, fleet_id=1, period_id=11, at=datetime(2031, 6, 1)) is None
    assert get("/fleet-prices/"+price["price_id"], fleet)["status"] == "draft"
    assert get("/fleet-prices?fleet_id=1&keyword="+price["price_id"], fleet)["total"] >= 1
    get("/fleet-bills/2", fleet, 403)
    fb = post("/fleet-bills", dict(fleet_id="1", bill_month="2026-11-01"), staff, 201)
    assert fb["payable_amount"] == "10.00" and fb["items"][0]["order_id"] == fleet_order
    assert get("/fleet-bills?keyword="+fb["bill_id"], fleet)["total"] >= 1
    path = "/fleet-bills/"+fb["bill_id"]
    request = dict(external_trade_no="V14-FLEET-1", amount="4.00")
    post(path+"/payments", request, fleet, 403)
    receipt = post(path+"/payments", request, staff, 201)
    assert post(path+"/payments", request, staff, 201) == receipt
    assert get(path, fleet)["status"] == "partially_paid"
    post(path+"/payments", dict(external_trade_no="V14-FLEET-2", amount="6.01"), staff, 409)
    post(path+"/payments", dict(external_trade_no="V14-FLEET-2", amount="6.00"), staff, 201)
    assert get(path, fleet)["paid_amount"] == "10.00" and get(path, fleet)["status"] == "paid"
    result = db.query(f"""INSERT INTO refund_record
        (payment_id,external_refund_no,amount,status,refunded_at,reason,requested_by,settlement_method)
        SELECT payment_id,'V14-FLEET-CREDIT',2,'succeeded','2026-12-05','V14 test',103,'fleet_credit'
        FROM payment_record WHERE order_id={int(fleet_order)} AND amount=6;
        INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,
            fleet_id,order_mode,status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,payable_amount)
        SELECT user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,
            fleet_id,'fleet','awaiting_payment','2026-12-04 13:30:00','2026-12-04 14:30:00',10,8,2,10
        FROM charging_order WHERE order_id={int(fleet_order)};""")
    assert not result.returncode, result.stderr
    credit_bill = post("/fleet-bills", dict(fleet_id="1", bill_month="2026-12-01"), staff, 201)
    assert credit_bill["payable_amount"] == "8.00" and credit_bill["adjustment_amount"] == "-2.00"
    credit_receipt = post(f"/fleet-bills/{credit_bill['bill_id']}/payments",
                          dict(external_trade_no="V14-FLEET-3", amount="8.00"), staff, 201)
    result = db.query(f"""SELECT SUM(amount),SUM(fleet_credit_amount) FROM payment_record
        WHERE bill_payment_id={int(credit_receipt['bill_payment_id'])};""")
    assert not result.returncode and result.stdout.strip().splitlines()[-1] == "10.00\t2.00", result

    result = db.query(f"""UPDATE charging_order SET status='paid' WHERE order_id={int(unpaid_order)};
        INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
        VALUES({int(unpaid_order)},'mock','V14-LATE',6,'succeeded','2026-12-02 14:35:00');""")
    assert not result.returncode, result.stderr
    later = post("/settlements", dict(operator_id="1", station_id="1", bill_month="2026-12-01"), admin, 201)
    assert any(i["order_id"] == unpaid_order and i["item_type"] == "order" for i in later["items"])
    assert any(i["order_id"] == paid_order and i["item_type"] == "refund" and i["net_amount"] == "-1.00"
               for i in later["items"])
    assert get("/settlements/"+sid, admin)["payable_amount"] == "4.57"
    post("/settlements", dict(operator_id="1", station_id="1", bill_month="2026-12-01"), admin, 409)


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="settlement-v14-contract-") as directory:
        instance = Instance(find_bin(None), Path(directory))
        try:
            instance.start()
            install_settlement_sql(instance)
            frontend = Path(directory) / "dist"
            frontend.mkdir()
            (frontend / "index.html").write_text("<main>test</main>", encoding="utf-8")
            app = create_app(f"mysql+pymysql://root@127.0.0.1:{instance.port}/charging_platform_test?charset=utf8mb4",
                             token_urlsafe(48), frontend)
            with TestClient(app) as client:
                contract(client)
                verify(instance, client)
            print("PASS: V1.4 routes, policies, differences, versioned adjustments, user invoices, fleet cash and late/refund settlement.")
        finally:
            instance.close()
