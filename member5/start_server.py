"""Start the local settlement workbench from a terminal or VS Code."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description="启动本地结算工作台")
    parser.add_argument("--port", type=int, default=8001, help="本地端口（默认 8001）")
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("端口必须在 1 到 65535 之间")

    root = Path(__file__).resolve().parent
    frontend = root / "frontend" / "dist"
    if not (frontend / "index.html").is_file():
        print("前端还未构建。请在项目根目录运行：npm.cmd --prefix frontend run build", file=sys.stderr)
        return 1

    venv = root / ".venv" / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    python = venv if venv.is_file() else sys.executable
    env = {**os.environ, "FRONTEND_DIST": str(frontend)}
    print(f"结算工作台：http://127.0.0.1:{args.port}/settlement/settlements", flush=True)
    print("看到 Uvicorn running 后即可打开网页。按 Ctrl+C 停止服务。", flush=True)
    try:
        return subprocess.call(
            [str(python), "-m", "uvicorn", "app.main:app", "--app-dir", str(root / "backend"),
             "--host", "127.0.0.1", "--port", str(args.port)],
            cwd=root,
            env=env,
        )
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
