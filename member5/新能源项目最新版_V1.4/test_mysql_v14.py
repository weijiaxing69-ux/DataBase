"""Run V1.4 database regression tests in a disposable local MySQL 8.0 instance.

Usage: python test_mysql_v14.py
Optional: --mysql-bin "C:/Program Files/MySQL/MySQL Server 8.0/bin"
Requires Python 3.10+ and the original V1.4 seed ZIP beside this file.
Exit 0: required database tests passed. Exit 1: setup or regression failed.
GAP entries are observations about rules assigned to the application in V1.4.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import zipfile
from concurrent.futures import ThreadPoolExecutor


ROOT = Path(__file__).resolve().parent
BUNDLE = ROOT / "新能源汽车充电平台_V1.4测试数据.zip"
DB = "charging_platform_test"
ORDER = """INSERT INTO charging_order
(user_id,gun_id,rule_id,operator_id,station_id,order_mode,status,started_at)
VALUES (1,1,1,1,1,'personal','charging','2026-11-13 13:30:00')"""
PAYMENT = """INSERT INTO payment_record
(order_id,channel,external_trade_no,amount,status,paid_at)
VALUES (1001,'mock','REGRESSION-PAY',2,'succeeded','2026-11-13 14:30:00')"""
LOCK_COUPON = """INSERT INTO coupon_usage
(coupon_id,order_id,original_amount,discount_amount,locked_at,lock_expires_at,status)
VALUES (21,1001,9,3,'2026-11-13 14:30:00','2026-11-13 14:45:00','locked')"""


def find_bin(override):
    if override:
        return Path(override).resolve()
    server = shutil.which("mysqld")
    if server:
        return Path(server).resolve().parent
    return Path(r"C:\Program Files\MySQL\MySQL Server 8.0\bin")


class Instance:
    def __init__(self, bin_dir, work):
        self.work = work
        self.exe = {
            name: str(bin_dir / (name + (".exe" if os.name == "nt" else "")))
            for name in ("mysql", "mysqld", "mysqladmin")
        }
        for executable in self.exe.values():
            if not Path(executable).is_file():
                raise FileNotFoundError(executable)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            self.port = listener.getsockname()[1]
        self.env = os.environ.copy()
        for name in ("MYSQL_PWD", "MYSQL_TEST_LOGIN_FILE", "MYSQL_TCP_PORT", "MYSQL_UNIX_PORT"):
            self.env.pop(name, None)
        self.env["MYSQL_TEST_LOGIN_FILE"] = str(self.work / "empty.mylogin.cnf")
        self.connect = [
            "--no-defaults", "--protocol=tcp", "--host=127.0.0.1",
            f"--port={self.port}", "--user=root", "--skip-password", "--connect-timeout=2",
        ]
        self.cli = [self.exe["mysql"], *self.connect, "--default-character-set=utf8mb4",
                    "--batch", "--skip-column-names", "--unbuffered"]
        self.process = None

    def start(self):
        server = [
            self.exe["mysqld"], "--no-defaults",
            f"--basedir={Path(self.exe['mysqld']).parent.parent}",
            f"--datadir={self.work / 'data'}", f"--log-error={self.work / 'mysql.err'}",
        ]
        self.run(server + ["--initialize-insecure"], timeout=120, check=True)
        self.process = subprocess.Popen(
            server + [f"--port={self.port}", "--bind-address=127.0.0.1", "--mysqlx=OFF",
                      "--skip-log-bin", "--innodb-flush-log-at-trx-commit=2"],
            env=self.env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        deadline = time.monotonic() + 60
        last_error = ""
        while time.monotonic() < deadline and self.process.poll() is None:
            probe = self.run(self.cli, input="SELECT @@datadir;", timeout=10)
            if probe.returncode == 0:
                if Path(probe.stdout.strip()).resolve() != (self.work / "data").resolve():
                    raise RuntimeError("Port responded from a different MySQL instance.")
                self.verified = True
                return
            last_error = probe.stderr.strip()
            time.sleep(.25)
        raise RuntimeError(f"Temporary MySQL did not become ready. {last_error}")

    def run(self, args, **kwargs):
        return subprocess.run(args, env=self.env, encoding="utf-8",
                              capture_output=True, **kwargs)

    def close(self):
        if self.process is None or self.process.poll() is not None:
            return
        try:
            if getattr(self, "verified", False):
                self.run([self.exe["mysqladmin"], *self.connect, "shutdown"], timeout=15)
            self.process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=10)

    def query(self, sql):
        return self.run(self.cli + [DB], input=sql, timeout=30)

    def load(self):
        with zipfile.ZipFile(BUNDLE) as bundle:
            for name in ("00_测试库建表.sql", "04_seed_V1.4.sql", "90_验收查询.sql"):
                result = self.run(self.cli, input=bundle.read(name).decode("utf-8-sig"),
                                  timeout=150, check=True)
        return result.stdout.splitlines()


def transaction(db, *statements):
    return db.query("START TRANSACTION;\n" + ";\n".join(statements) + ";\nROLLBACK;\n")


def rejected(result, code, marker):
    if result.returncode == 0 or not re.search(rf"ERROR {code}\b", result.stderr) or marker not in result.stderr:
        raise AssertionError(f"Expected MySQL {code} / {marker}, got: {result.stderr or result.stdout or 'accepted'}")


def expect(result, *lines):
    if result.returncode or result.stdout.splitlines() != list(lines):
        raise AssertionError(f"Expected {lines!r}; got {result.stdout!r} {result.stderr}")


def concurrent_start(db):
    with subprocess.Popen(db.cli + [DB], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, env=db.env, encoding="utf-8") as leader:
        try:
            leader.stdin.write(f"START TRANSACTION;\n{ORDER};\nSELECT 'inserted';\n")
            leader.stdin.flush()
            with ThreadPoolExecutor() as pool:
                ready = pool.submit(leader.stdout.readline)
                if ready.result(timeout=10).strip() != "inserted":
                    raise AssertionError("First session did not insert.")
                contender = pool.submit(db.query, f"SET SESSION innodb_lock_wait_timeout=12;\n{ORDER};")
                deadline = time.monotonic() + 7
                waiting = False
                while time.monotonic() < deadline and not contender.done():
                    locks = db.query("SELECT COUNT(*) FROM performance_schema.data_lock_waits;")
                    if locks.returncode != 0:
                        raise AssertionError(locks.stderr)
                    if int(locks.stdout.strip()) > 0:
                        waiting = True
                        break
                    time.sleep(.08)
                leader.stdin.write("COMMIT;\n")
                leader.stdin.close()
                if leader.wait(timeout=8) != 0:
                    raise AssertionError(leader.stderr.read())
                rejected(contender.result(timeout=14), 1062, "uq_charging_order_active_gun_id")
                if not waiting:
                    raise AssertionError("Second session did not demonstrably wait on the first session's lock.")
            expect(db.query("SELECT COUNT(*) FROM charging_order WHERE active_gun_id=1;"), "1")
        finally:
            if leader.poll() is None:
                leader.kill()
                leader.wait(timeout=5)


def test_cases(db, baseline):
    expected = ["65", "history_order_payment_mismatch\t0", "history_order_billing_mismatch\t0",
                "history_settlement_amount_mismatch\t0", "history_fleet_payment_mismatch\t0",
                "21\t1\tavailable", "L01 expected\t6.40\t2.60\t6.00", "L02 expected\t6.00", "1900"]
    def check_baseline():
        if baseline != expected:
            raise AssertionError(f"Unexpected baseline: {baseline!r}")

    yield "D01 基线行数、四项金额核对和两笔计费算例", check_baseline
    yield "D02 拒绝引用不存在的运营商", lambda: rejected(transaction(db,
        "UPDATE station SET operator_id=999999 WHERE station_id=1"), 1452, "fk_station_operator_id")
    yield "D03 拒绝删除仍被引用的运营商", lambda: rejected(transaction(db,
        "DELETE FROM operator WHERE operator_id=1"), 1451, "REFERENCES `operator`")
    yield "D04 拒绝设备日志同时指定桩和枪", lambda: rejected(transaction(db,
        "INSERT INTO device_status_log(pile_id,gun_id,new_status,occurred_at,reason) VALUES(1,1,'idle',UTC_TIMESTAMP(),'test')"),
        3819, "ck_device_status_log_1")
    yield "D05 拒绝同规则的重复时段起点", lambda: rejected(transaction(db,
        "INSERT INTO pricing_period(rule_id,period_type,start_minute,end_minute,electricity_rate,service_rate) VALUES(1,'peak',1080,1320,0.8,0.3)"),
        1062, "uq_pricing_period_rule_id_start_minute")
    yield "D06 拒绝负电价", lambda: rejected(transaction(db,
        "UPDATE pricing_period SET electricity_rate=-1 WHERE period_id=13"), 3819, "ck_pricing_period_3")
    yield "D07 拒绝 SOC 超过 100", lambda: rejected(transaction(db,
        "UPDATE charging_order SET end_soc=101 WHERE order_id=1"), 3819, "ck_charging_order_4")
    yield "D08 拒绝没有授权和车辆的车队订单", lambda: rejected(transaction(db,
        ORDER.replace("'personal'", "'fleet'")), 3819, "ck_charging_order_1")
    yield "D09 拒绝非正数支付金额", lambda: rejected(transaction(db,
        PAYMENT.replace("'REGRESSION-PAY',2", "'REGRESSION-PAY',0")), 3819, "ck_payment_record_1")
    yield "D10 同渠道重复支付流水被拒绝", lambda: rejected(transaction(db, PAYMENT, PAYMENT),
        1062, "uq_payment_record_channel_external_trade_no")
    yield "D11 有效券不能同时锁给两个订单", lambda: rejected(transaction(db, LOCK_COUPON,
        LOCK_COUPON.replace("21,1001", "21,1002")), 1062, "uq_coupon_usage_active_coupon_id")
    yield "D12 释放券后可重新锁券", lambda: expect(transaction(db, LOCK_COUPON,
        "UPDATE coupon_usage SET status='released',released_at='2026-11-13 14:31:00' WHERE coupon_id=21",
        LOCK_COUPON.replace("21,1001", "21,1002"),
        "SELECT order_id FROM coupon_usage WHERE active_coupon_id=21"), "1002")
    yield "D13 一辆车不能同时存在两个当前绑定", lambda: rejected(transaction(db,
        "INSERT INTO vehicle_binding(user_id,vehicle_id,bound_at) VALUES(2,1,UTC_TIMESTAMP())"),
        1062, "uq_vehicle_binding_active_vehicle_id")
    yield "D14 运行数据触发器拒绝不存在的桩", lambda: rejected(transaction(db,
        "INSERT INTO device_reading(pile_id,sampled_at,output_voltage_v,output_current_a,power_kw,module_temperature_c) VALUES(999999,'2026-11-13 02:00:00',400,0,0,25)"),
        1644, "pile not found")
    yield "D15 有效采样按月份与桩落入子分区", lambda: expect(transaction(db,
        "INSERT INTO device_reading(sample_id,pile_id,sampled_at,output_voltage_v,output_current_a,power_kw,module_temperature_c) VALUES(999999,1,'2026-11-13 02:00:00',400,0,0,25)",
        "SELECT COUNT(*) FROM device_reading PARTITION(p202611) WHERE sample_id=999999 AND pile_id=1"), "1")
    yield "D16 同运营商同场站同账期结算唯一", lambda: rejected(transaction(db,
        "INSERT INTO operator_settlement(operator_id,station_id,bill_month) VALUES(1,1,'2026-10-01')"),
        1062, "uq_operator_settlement_operator_id_station_id_bill_month")
    confirm = """INSERT INTO reconciliation_confirmation
    (settlement_id,object_version,side,decision,confirmed_by,confirmed_at)
    VALUES(1,2,'platform','confirmed',101,UTC_TIMESTAMP())"""
    yield "D17 同对象版本同方的当前确认唯一", lambda: rejected(transaction(db, confirm),
        1062, "uq_reconciliation_confirmation_current_key")
    yield "D18 新版本可独立记录确认", lambda: expect(transaction(db,
        "UPDATE operator_settlement SET version=3,status='pending_confirmation' WHERE settlement_id=1",
        confirm.replace("VALUES(1,2", "VALUES(1,3"),
        "SELECT COUNT(*) FROM reconciliation_confirmation WHERE settlement_id=1 AND object_version=3 AND is_current=1"), "1")
    yield "D19 对账确认对象必须二选一", lambda: rejected(transaction(db,
        confirm.replace("(settlement_id,", "(settlement_id,difference_id,").replace("VALUES(1,2", "VALUES(1,1,2")),
        3819, "ck_reconciliation_confirmation_1")
    yield "D20 红票必须关联原票", lambda: rejected(transaction(db,
        """INSERT INTO operator_invoice(settlement_id,invoice_no,invoice_type,title,tax_no,amount,status,issued_at,issued_by)
        VALUES(1,'REG-RED','red','测试','DEMO',1,'red_issued',UTC_TIMESTAMP(),103)"""),
        3819, "ck_operator_invoice_2")
    yield "D21 同一价格目标最多一条待审批", lambda: rejected(transaction(db,
        """INSERT INTO pricing_review(rule_id,requested_by,requested_at,content_hash,target_snapshot)
        VALUES (1,103,UTC_TIMESTAMP(),UNHEX(SHA2('test',256)),JSON_OBJECT()),
        (1,103,UTC_TIMESTAMP(),UNHEX(SHA2('test',256)),JSON_OBJECT())"""),
        1062, "uq_pricing_review_pending_target_key")

    def rollback():
        expect(db.query("START TRANSACTION;\n" + ORDER + ";\n" + LOCK_COUPON + ";\n"
                        "SELECT COUNT(*) FROM charging_order WHERE active_gun_id=1;\n"
                        "SELECT COUNT(*) FROM coupon_usage WHERE active_coupon_id=21;\nROLLBACK;\n"
                        "SELECT COUNT(*) FROM charging_order WHERE active_gun_id=1;\n"
                        "SELECT COUNT(*) FROM coupon_usage WHERE active_coupon_id=21;"),
               "1", "1", "0", "0")

    yield "D22 回滚后订单和锁券记录都消失", rollback
    yield "D23 两个真实会话并发启动同一枪仅一笔成功", lambda: concurrent_start(db)


def boundaries():
    return [
        ("价格时段重叠", "INSERT INTO pricing_period(rule_id,period_type,start_minute,end_minute,electricity_rate,service_rate) VALUES(1,'peak',1100,1300,0.8,0.3)"),
        ("累计退款超原实付", """INSERT INTO refund_record(payment_id,external_refund_no,amount,status,refunded_at,reason,requested_by)
        VALUES(1,'REG-OVER-REFUND',99999,'succeeded',UTC_TIMESTAMP(),'测试',103)"""),
        ("累计开票超应结", """INSERT INTO operator_invoice(settlement_id,invoice_no,invoice_type,title,tax_no,amount,status,issued_at,issued_by)
        VALUES(1,'REG-OVER-INVOICE','blue','测试','DEMO',99999,'issued',UTC_TIMESTAMP(),103)"""),
        ("未完成双方确认即开票", """INSERT INTO operator_settlement(settlement_id,operator_id,station_id,bill_month,payable_amount)
        VALUES(999999,1,1,'2026-11-01',10)""",
        """INSERT INTO operator_invoice(settlement_id,invoice_no,invoice_type,title,tax_no,amount,status,issued_at,issued_by)
        VALUES(999999,'REG-NO-CONFIRM','blue','测试','DEMO',5,'issued',UTC_TIMESTAMP(),103)"""),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mysql-bin")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="codex-charging-regression-") as tmp:
        db = Instance(find_bin(args.mysql_bin), Path(tmp))
        try:
            print("正在初始化隔离 MySQL 实例并导入 V1.4 测试数据……", flush=True)
            db.start()
            baseline = db.load()
            print("MySQL", db.query("SELECT VERSION();").stdout.strip(), flush=True)
            passed = failed = gaps = 0
            for label, run in test_cases(db, baseline):
                try:
                    run()
                except (AssertionError, subprocess.SubprocessError) as exc:
                    failed += 1
                    print(f"FAIL {label}: {exc}", flush=True)
                else:
                    passed += 1
                    print(f"PASS {label}", flush=True)
            for label, *statements in boundaries():
                result = transaction(db, *statements)
                if result.returncode == 0:
                    gaps += 1
                    print(f"GAP  {label}：直接写 SQL 可以通过，应用事务仍需校验。", flush=True)
                elif re.search(r"ERROR (1062|1451|1452|1644|3819)\b", result.stderr):
                    print(f"GUARDED {label}: {result.stderr.strip()}", flush=True)
                else:
                    failed += 1
                    print(f"FAIL {label}: {result.stderr.strip()}", flush=True)
            print(f"约束测试 {passed} 通过 / {failed} 失败，应用规则缺口 {gaps} 项。", flush=True)
            return int(failed > 0)
        except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
            print(f"ERROR {exc}", file=sys.stderr)
            if isinstance(exc, subprocess.CalledProcessError):
                print(exc.stderr, file=sys.stderr)
            log = Path(tmp) / "mysql.err"
            if log.exists():
                print("\n".join(log.read_text(encoding="utf-8", errors="replace").splitlines()[-8:]), file=sys.stderr)
            return 1
        finally:
            db.close()


if __name__ == "__main__":
    sys.exit(main())
