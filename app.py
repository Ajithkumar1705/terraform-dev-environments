from flask import Flask
import os
import socket

app = Flask(__name__)


@app.route("/")
def home():
    return {
        "message": "Hello from your dev environment!",
        "hostname": socket.gethostname(),
    }


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    # 0.0.0.0 so the app is reachable from outside the instance
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))

