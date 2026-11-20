"""Run settlement acceptance scripts and save dated UTF-8 evidence logs."""
from datetime import datetime, timezone
from pathlib import Path
import os
import platform
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]


def main():
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    folder = Path(__file__).resolve().parent / "results" / stamp
    folder.mkdir(parents=True)
    tests = [("pytest", ["-m", "pytest", "-q", "backend/tests/settlement",
                         "--junitxml="+str(folder / "pytest.xml")])]
    passed = True
    summary = [f"UTC: {datetime.now(timezone.utc).isoformat()}",
               f"Python: {platform.python_version()}", "Database: isolated MySQL; not the local application database."]
    for name, arguments in tests:
        print(f"RUN: {name}", flush=True)
        with (folder / (name + ".log")).open("w", encoding="utf-8") as log:
            with subprocess.Popen([sys.executable, "-u", *arguments], cwd=ROOT,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  encoding="utf-8", errors="replace",
                                  env={**os.environ, "PYTHONIOENCODING": "utf-8"}) as process:
                for line in process.stdout:
                    log.write(line)
                    log.flush()
                    print(line, end="", flush=True)
                code = process.wait()
        summary.append(f"{'PASS' if code == 0 else 'FAIL'}: {name}; exit={code}")
        passed = passed and code == 0
    (folder / "summary.txt").write_text("\n".join(summary)+"\n", encoding="utf-8")
    print(f"Evidence: {folder}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
