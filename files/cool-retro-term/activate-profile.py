"""Select the managed cool-retro-term 1.2 profile without replacing other settings."""

import json
import os
from pathlib import Path
import sqlite3
import sys


profile_file = Path(sys.argv[1])
profile = json.loads(profile_file.read_text())
name = profile.pop("name")
assert profile.pop("version") == 2

data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
db_dir = data_home / "cool-retro-term/cool-retro-term/QML/OfflineStorage/Databases"
db_dir.mkdir(parents=True, exist_ok=True)
# Qt LocalStorage names the SQLite file with the MD5 of "coolretroterm1".
db_name = "27e743fe85b8912a46804fed99e8a9ab"
ini_file = db_dir / f"{db_name}.ini"
if not ini_file.exists():
    ini_file.write_text(
        "[General]\nDescription=StorageDatabase\nDriver=QSQLITE\n"
        "EstimatedSize=100000\nName=coolretroterm1\nVersion=1.0\n"
    )

with sqlite3.connect(db_dir / f"{db_name}.sqlite") as db:
    db.execute("CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)")
    row = db.execute(
        "SELECT value FROM settings WHERE setting = '_CUSTOM_PROFILES'"
    ).fetchone()
    custom_profiles = json.loads(row[0]) if row else []
    custom_profiles = [item for item in custom_profiles if item["text"] != name]
    custom_profiles.append(
        {"text": name, "obj_string": json.dumps(profile), "builtin": False}
    )
    for key, value in (
        ("_CURRENT_PROFILE", profile),
        ("_CUSTOM_PROFILES", custom_profiles),
    ):
        db.execute(
            "INSERT OR REPLACE INTO settings(setting, value) VALUES (?, ?)",
            (key, json.dumps(value)),
        )
