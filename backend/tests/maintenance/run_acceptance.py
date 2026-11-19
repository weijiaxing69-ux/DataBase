"""维护模块验收留痕：把真实 MySQL 上的测试结果写入带时间戳的目录。"""

from __future__ import annotations

import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BACKEND = ROOT / "backend"
HERE = Path(__file__).resolve().parent

JOBS = [
    ("seed_counts", [sys.executable, "-u", str(HERE / "check_seed_counts.py")], ROOT),
    ("full_tests", [sys.executable, "-u", "-m", "pytest", "tests", "-q"], BACKEND),
    ("maintenance_tests", [sys.executable, "-u", "-m", "pytest", "tests/maintenance", "-q"], BACKEND),
]


def main() -> int:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    folder = HERE / "results" / stamp
    folder.mkdir(parents=True)
    passed = True
    summary = [
        f"UTC: {datetime.now(timezone.utc).isoformat()}",
        f"Python: {platform.python_version()}",
        "Database: isolated MySQL charging_platform_test (rebuild_demo_db.py --with-emergency)",
        "Scope: maintenance service/integration/HTTP smoke + two-client concurrency",
    ]
    for name, command, cwd in JOBS:
        print(f"RUN {name}: {' '.join(command)}", flush=True)
        with (folder / f"{name}.log").open("w", encoding="utf-8") as log:
            process = subprocess.Popen(
                command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                encoding="utf-8", errors="replace", env={**os.environ, "PYTHONIOENCODING": "utf-8"},
            )
            for line in process.stdout:
                log.write(line)
                log.flush()
                print(line, end="", flush=True)
            code = process.wait()
        summary.append(f"{'PASS' if code == 0 else 'FAIL'}: {name}; exit={code}")
        passed &= code == 0
    (folder / "summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    print(f"Evidence: {folder}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
