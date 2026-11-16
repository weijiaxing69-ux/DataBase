"""Install member 2 views, procedure and trigger in the V1.4 database."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent / "database" / "modules" / "billing"
SQL_FILES = ("04_views.sql", "05_procedures.sql", "06_triggers.sql")


def main():
    prefix = (
        "SET NAMES utf8mb4; USE charging_platform; "
        "DROP PROCEDURE IF EXISTS sp_billing_expire_unpaid; "
        "DROP TRIGGER IF EXISTS trg_billing_meter_reading_validate;\n"
    )
    source = prefix + "\n".join((ROOT / name).read_text(encoding="utf-8") for name in SQL_FILES)
    command = ["docker", "exec", "-i", "mysql8", "sh", "-c", 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot']
    result = subprocess.run(command, input=source.encode("utf-8"), capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace"))
    print("Installed billing views, procedure and trigger")


if __name__ == "__main__":
    main()
