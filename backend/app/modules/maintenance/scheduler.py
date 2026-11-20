"""维护模块后台任务调度器。

设计成独立进程，而不是塞进 Web 进程启动钩子：
- 不修改共享 `app/main.py`，避免多人合并冲突；
- 可以单独部署、单独重启、单独看日志；
- 用 MySQL `GET_LOCK` 防止多实例重复执行同一轮任务。

启动：
    cd backend
    python -m app.modules.maintenance.scheduler

也可以由部署脚本拉起；停止用 Ctrl+C。
"""

from __future__ import annotations

import logging
import os
import signal
import threading
import time
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.modules.maintenance import service

logger = logging.getLogger("maintenance.scheduler")

# 每个任务的建议执行间隔（秒）。低频任务不跟随 30 秒轮询。
TASK_INTERVALS: dict[str, int] = {
    "offline": 60,
    "overdue": 60,
    "recovery": 60,
    "charging": 60,
    "safety": 60,
    "recurring": 300,
    "inspection": 3600,
    "temperature": 60,
    "metering": 60,
    "occupied": 300,
    "overload": 60,
    "duration": 300,
    "voltage": 60,
    "gun_mismatch": 60,
    "fault_state_mismatch": 300,
    "sampling_gap": 60,
}

LOCK_NAME = "charging_maintenance_scheduler"
POLL_SECONDS = int(os.getenv("MAINTENANCE_SCHEDULER_POLL_SECONDS", "30"))

_stop_event: Optional[threading.Event] = None
_thread: Optional[threading.Thread] = None


def run_due_tasks(
    db: Session, *, now: datetime, last_runs: dict[str, datetime], force: bool = False
) -> dict[str, int]:
    """执行到期任务，返回本轮各任务影响条数；单个任务失败不阻断其他任务。"""
    result: dict[str, int] = {}
    for name, interval in TASK_INTERVALS.items():
        if not force and name in last_runs:
            if now - last_runs[name] < timedelta(seconds=interval):
                continue
        task = service.TASKS.get(name)
        if task is None:
            logger.error("scheduler task missing: %s", name)
            continue
        try:
            result[name] = int(task(db, now=now))
        except Exception:  # noqa: BLE001 逐任务隔离，调度器不能因单任务退出
            logger.exception("scheduler task failed: %s", name)
            continue
        last_runs[name] = now
    return result


def _loop(stop_event: threading.Event) -> None:
    last_runs: dict[str, datetime] = {}
    while not stop_event.is_set():
        now = service.utcnow()
        with SessionLocal() as db:
            try:
                locked = db.execute(
                    text("select get_lock(:name, 0)"), {"name": LOCK_NAME}
                ).scalar()
                if locked == 1:
                    try:
                        changed = run_due_tasks(db, now=now, last_runs=last_runs)
                        if changed:
                            logger.info("scheduler round: %s", changed)
                    finally:
                        db.execute(text("select release_lock(:name)"), {"name": LOCK_NAME})
                else:
                    logger.debug("scheduler lock held by another instance")
            except Exception:  # noqa: BLE001
                logger.exception("scheduler round failed")
        stop_event.wait(POLL_SECONDS)


def start_background_scheduler() -> threading.Event:
    """启动守护线程；重复调用返回同一个停止事件。"""
    global _thread, _stop_event
    if _thread is not None and _thread.is_alive():
        return _stop_event  # type: ignore[return-value]
    stop_event = threading.Event()
    thread = threading.Thread(target=_loop, args=(stop_event,), name="maintenance-scheduler", daemon=True)
    thread.start()
    _thread, _stop_event = thread, stop_event
    logger.info("maintenance scheduler started, poll=%ss", POLL_SECONDS)
    return stop_event


def stop_background_scheduler() -> None:
    global _stop_event
    if _stop_event is not None:
        _stop_event.set()
        logger.info("maintenance scheduler stopped")


def main() -> int:
    logging.basicConfig(
        level=os.getenv("MAINTENANCE_SCHEDULER_LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    stop_event = start_background_scheduler()

    def _stop(signum, frame):  # noqa: ANN001
        stop_background_scheduler()

    try:
        signal.signal(signal.SIGINT, _stop)
        signal.signal(signal.SIGTERM, _stop)
    except (ValueError, AttributeError):
        pass

    try:
        while _thread is not None and _thread.is_alive():
            time.sleep(1)
    except KeyboardInterrupt:
        stop_background_scheduler()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
