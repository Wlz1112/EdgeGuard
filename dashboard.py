"""EdgeGuard device dashboard."""
import datetime
import json
import socket
import subprocess
import sys
from pathlib import Path

import psutil
from flask import Flask, jsonify, send_file

app = Flask(__name__)
logs = Path("/var/log/edgeguard")


@app.get("/")
def home():
    return send_file(Path(__file__).with_name("dashboard-live.html"))


@app.get("/api/live")
def live():
    mode = Path("/etc/edgeguard/mode").read_text().strip()
    active = subprocess.run(["systemctl", "is-active", "--quiet", "edgeguard-engine"]).returncode == 0
    now = datetime.datetime.now(datetime.timezone.utc)
    rows = []
    if (logs / "eve.json").is_file():
        with (logs / "eve.json").open("rb") as stream:
            stream.seek(0, 2)
            start = max(0, stream.tell() - 2 * 1024 * 1024)
            stream.seek(start)
            if start:
                stream.readline()
            for line in stream:
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if event.get("event_type") == "alert":
                    age = (now - datetime.datetime.fromisoformat(event["timestamp"])).total_seconds()
                    if 0 <= age < 3600:
                        rows.append(event)
    archive = logs / "experiment-alerts"
    for path in sorted(archive.glob("*-alerts.jsonl")):
        with path.open() as stream:
            for line in stream:
                event = json.loads(line)
                if event.get("event_type") == "alert":
                    event["experiment_source"] = path.name
                    rows.append(event)
    rows.sort(key=lambda event: datetime.datetime.fromisoformat(event["timestamp"]))
    temp = Path("/sys/class/thermal/thermal_zone0/temp")
    return jsonify(device=socket.gethostname(), ip=sys.argv[1], business_port=int(sys.argv[3]), now=now.timestamp(),
                   mode=mode.upper() if active or mode == "baseline" else "离线",
                   cpu=psutil.cpu_percent(interval=0.12), ram=psutil.virtual_memory().percent,
                   temp=float(temp.read_text()) / 1000 if temp.exists() else None, events=rows[::-1])


if __name__ == "__main__":
    app.run(host=sys.argv[1], port=int(sys.argv[2]))


