"""Optional HTTP service for verifying IDS/IPS with benign requests."""
import sys
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/api/status")
@app.get("/lab/blocked")
def status():
    return jsonify(service="EdgeGuard demo", status="ok")


if __name__ == "__main__":
    app.run(host=sys.argv[1], port=int(sys.argv[2]))
