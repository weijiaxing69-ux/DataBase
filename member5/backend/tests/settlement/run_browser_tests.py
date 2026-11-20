"""Build and test the real Vue + FastAPI application on an isolated MySQL instance."""
import os
from pathlib import Path
from secrets import token_urlsafe
import shutil
import socket
import subprocess
import sys
import tempfile
import time

import httpx

from support import ROOT, Instance, find_bin, install_settlement_sql


def main():
    npm = shutil.which("npm.cmd" if os.name == "nt" else "npm")
    if not npm:
        raise RuntimeError("Node.js/npm is required")
    subprocess.run([npm, "--prefix", str(ROOT / "frontend"), "run", "build"], check=True)
    with tempfile.TemporaryDirectory(prefix="settlement-browser-") as directory:
        instance = Instance(find_bin(None), Path(directory))
        server = None
        try:
            instance.start()
            install_settlement_sql(instance)
            seed = instance.query("""
                INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,
                  status,started_at,finished_at,energy_kwh,electricity_amount,service_amount,
                  discount_amount,payable_amount)
                VALUES(1,1,1,1,1,'personal','paid','2026-11-12 13:30:00','2026-11-12 14:30:00',10,6.40,2.60,3,6);
                SET @personal=LAST_INSERT_ID();
                INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
                VALUES(@personal,'mock','BROWSER-PAID',6,'succeeded','2026-11-12 14:35:00');
                INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,
                  station_id,fleet_id,order_mode,status,started_at,finished_at,energy_kwh,electricity_amount,
                  service_amount,payable_amount)
                SELECT user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,fleet_id,
                  'fleet','awaiting_payment','2026-11-14','2026-11-14 01:00:00',10,8,2,10
                FROM charging_order WHERE order_id=101;
                SELECT @personal;
            """)
            seed.check_returncode()
            oid = seed.stdout.strip().splitlines()[-1]
            with socket.socket() as listener:
                listener.bind(("127.0.0.1", 0))
                port = listener.getsockname()[1]
            origin = f"http://127.0.0.1:{port}"
            env = {**os.environ, "DATABASE_URL":
                f"mysql+pymysql://root@127.0.0.1:{instance.port}/charging_platform_test?charset=utf8mb4",
                "JWT_SECRET": token_urlsafe(48), "FRONTEND_DIST": str(ROOT / "frontend/dist"),
                "E2E_BASE_URL": origin, "E2E_ORDER_ID": oid}
            with (ROOT / "frontend" / "test-server.log").open("w", encoding="utf-8") as log:
                server = subprocess.Popen([sys.executable, "-m", "uvicorn", "app.main:app",
                    "--app-dir", str(ROOT / "backend"), "--host", "127.0.0.1", "--port", str(port)],
                    env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
                with httpx.Client(trust_env=False) as client:
                    deadline = time.monotonic()+30
                    while time.monotonic() < deadline:
                        if server.poll() is not None:
                            raise RuntimeError("Test server failed; see frontend/test-server.log")
                        try:
                            if client.get(origin+"/openapi.json").status_code == 200:
                                break
                        except httpx.TransportError:
                            pass
                        time.sleep(0.2)
                    else:
                        raise RuntimeError("Test server did not become ready")
                evidence = ROOT / "backend/tests/settlement/results/browser"
                evidence.mkdir(parents=True, exist_ok=True)
                with (evidence / "playwright.log").open("w", encoding="utf-8") as output:
                    with subprocess.Popen([npm, "exec", "--", "playwright", "test"],
                        cwd=ROOT / "frontend", env=env, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, encoding="utf-8", errors="replace") as run:
                        for line in run.stdout:
                            output.write(line)
                            output.flush()
                            print(line, end="", flush=True)
                        return run.wait()
        finally:
            if server and server.poll() is None:
                server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()
            instance.close()


if __name__ == "__main__":
    raise SystemExit(main())
