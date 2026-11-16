"""Load the V1.4 schema into the project database in the local MySQL container."""
from pathlib import Path
import json
import subprocess

DATABASE = "charging_platform"
SOURCE = Path(__file__).resolve().parent / "database" / "reference" / "unified_schema_v1.4.sql"


def main():
    source = SOURCE.read_text(encoding="utf-8-sig")
    assert f"use {DATABASE};" in source
    inspect = subprocess.check_output(["docker", "inspect", "mysql8"], text=True)
    env = dict(item.split("=", 1) for item in json.loads(inspect)[0]["Config"]["Env"] if "=" in item)
    assert env.get("MYSQL_ROOT_PASSWORD"), "MySQL root password is unavailable in container environment"
    command = ["docker", "exec", "-i", "mysql8", "sh", "-c", 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot']
    result = subprocess.run(command, input=source.encode("utf-8"), capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip())
    print(f"Loaded {DATABASE} from {SOURCE.name}")
    from install_billing_sql import main as install_billing_sql
    install_billing_sql()


if __name__ == "__main__":
    main()
