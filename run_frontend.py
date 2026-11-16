"""PyCharm one-click launcher for the Vite frontend."""
from pathlib import Path
import subprocess


if __name__ == "__main__":
    frontend = Path(__file__).resolve().parent / "frontend"
    subprocess.run(["npm.cmd", "run", "dev"], cwd=frontend, check=True)
