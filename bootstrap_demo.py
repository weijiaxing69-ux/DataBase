"""Create a local demo administrator. Keep credentials out of source control."""
from pathlib import Path
import secrets

from backend import password_hash
from db_connection import connect

ROOT = Path(__file__).resolve().parent
CREDENTIALS = ROOT / "demo-login.txt"


def main():
    if CREDENTIALS.exists():
        print(f"Credentials already exist: {CREDENTIALS}")
        return
    username = "demo_admin"
    password = secrets.token_urlsafe(18)
    db = connect()
    with db.cursor() as cur:
        cur.execute("INSERT INTO sys_role(role_code,role_name) VALUES ('platform_admin','平台管理员') ON DUPLICATE KEY UPDATE role_name=VALUES(role_name)")
        cur.execute("SELECT role_id FROM sys_role WHERE role_code='platform_admin'")
        role_id = cur.fetchone()["role_id"]
        cur.execute("INSERT INTO sys_account(username,password_hash,status,failed_attempts,locked_until) VALUES (%s,%s,'active',0,NULL) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash),status='active',failed_attempts=0,locked_until=NULL", (username,password_hash(password)))
        cur.execute("SELECT account_id FROM sys_account WHERE username=%s", (username,))
        account_id = cur.fetchone()["account_id"]
        cur.execute("INSERT IGNORE INTO sys_account_role(account_id,role_id) VALUES (%s,%s)", (account_id,role_id))
    db.commit()
    db.close()
    CREDENTIALS.write_text(f"本地演示账号（请勿提交到仓库）\n账号：{username}\n密码：{password}\n", encoding="utf-8")
    print(f"Created local demo credentials: {CREDENTIALS}")


if __name__ == "__main__":
    main()
