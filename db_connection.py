"""Local development connection to the user's MySQL 8 container."""
import json
import os
import subprocess
from functools import lru_cache
import pymysql


@lru_cache(maxsize=1)
def local_container_password():
    details = json.loads(subprocess.check_output(["docker", "inspect", "mysql8"], text=True))[0]
    variables = dict(item.split("=", 1) for item in details["Config"]["Env"] if "=" in item)
    return variables["MYSQL_ROOT_PASSWORD"]


def connect(database="charging_platform", *, autocommit=False):
    password = os.environ.get("CHARGING_DB_PASSWORD")
    if password is None:
        password = local_container_password()
    return pymysql.connect(host="127.0.0.1", port=3307, user="root", password=password,
                           database=database, charset="utf8mb4", autocommit=autocommit,
                           cursorclass=pymysql.cursors.DictCursor)
