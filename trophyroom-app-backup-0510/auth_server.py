#!/usr/bin/env python3
"""
auth_server.py — TrophyRoom 账号与数据同步服务器
纯 Python 标准库，无需外部依赖
"""

import json
import os
import sqlite3
import hashlib
import secrets
import time
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from pathlib import Path

# ─── 配置 ───────────────────────────────────────────────

PORT = 8768
HOST = "0.0.0.0"
DB_PATH = "/root/trophyroom_auth.db"
TOKEN_EXPIRE_DAYS = 30
PING_TIMEOUT_SECONDS = 300  # 5分钟未 ping 视为离线
ADMIN_USERNAME = "shinyyann"

# ─── 数据库 ─────────────────────────────────────────────

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS tokens (
            token TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            expires_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS user_data (
            user_id INTEGER PRIMARY KEY,
            data TEXT DEFAULT '{}',
            updated_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS pings (
            user_id INTEGER PRIMARY KEY,
            last_ping REAL NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    conn.commit()
    return conn


def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()


def generate_token():
    return secrets.token_hex(32)


def create_user(username, password):
    conn = get_db()
    try:
        conn.execute(
            "INSERT INTO users (username, password_hash) VALUES (?, ?)",
            (username, hash_password(password))
        )
        conn.commit()
        user = conn.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone()
        conn.execute(
            "INSERT OR IGNORE INTO user_data (user_id, data) VALUES (?, '{}')",
            (user["id"],)
        )
        conn.commit()
        return user["id"]
    except sqlite3.IntegrityError:
        return None


def verify_user(username, password):
    conn = get_db()
    user = conn.execute(
        "SELECT id, password_hash FROM users WHERE username = ?",
        (username,)
    ).fetchone()
    if user and user["password_hash"] == hash_password(password):
        return user["id"]
    return None


def issue_token(user_id):
    conn = get_db()
    token = generate_token()
    expires = (datetime.now() + timedelta(days=TOKEN_EXPIRE_DAYS)).isoformat()
    conn.execute(
        "INSERT INTO tokens (token, user_id, expires_at) VALUES (?, ?, ?)",
        (token, user_id, expires)
    )
    conn.commit()
    return token


def verify_token(token):
    conn = get_db()
    row = conn.execute(
        """SELECT t.user_id, t.expires_at, u.username
           FROM tokens t JOIN users u ON t.user_id = u.id
           WHERE t.token = ?""", (token,)
    ).fetchone()
    if not row:
        return None
    expires = datetime.fromisoformat(row["expires_at"])
    if datetime.now() > expires:
        return None
    return {"user_id": row["user_id"], "username": row["username"]}


def get_user_data(user_id):
    conn = get_db()
    row = conn.execute(
        "SELECT data FROM user_data WHERE user_id = ?", (user_id,)
    ).fetchone()
    if row:
        return json.loads(row["data"])
    return {}


def save_user_data(user_id, data):
    conn = get_db()
    conn.execute(
        """INSERT INTO user_data (user_id, data, updated_at)
           VALUES (?, ?, datetime('now'))
           ON CONFLICT(user_id)
           DO UPDATE SET data = ?, updated_at = datetime('now')""",
        (user_id, json.dumps(data), json.dumps(data))
    )
    conn.commit()


def update_ping(user_id):
    conn = get_db()
    now = time.time()
    conn.execute(
        """INSERT INTO pings (user_id, last_ping) VALUES (?, ?)
           ON CONFLICT(user_id) DO UPDATE SET last_ping = ?""",
        (user_id, now, now)
    )
    conn.commit()


def get_admin_stats():
    conn = get_db()
    total_users = conn.execute("SELECT COUNT(*) as c FROM users").fetchone()["c"]
    cutoff = time.time() - PING_TIMEOUT_SECONDS
    online = conn.execute(
        "SELECT COUNT(*) as c FROM pings WHERE last_ping > ?", (cutoff,)
    ).fetchone()["c"]
    total_data = conn.execute("SELECT COUNT(*) as c FROM user_data").fetchone()["c"]
    return {
        "total_users": total_users,
        "online_users": online,
        "total_data_count": total_data,
    }


# ─── HTTP Handler ───────────────────────────────────────

class AuthHTTPHandler(BaseHTTPRequestHandler):

    def _json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode())

    def _error(self, msg, status=400):
        self._json({"error": msg}, status)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        body = self.rfile.read(length)
        return json.loads(body.decode())

    def _auth_required(self):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return None
        token = auth[7:]
        return verify_token(token)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_POST(self):
        path = self.path.rstrip("/")

        if path == "/register":
            body = self._read_body()
            username = body.get("username", "").strip()
            password = body.get("password", "")

            if not username or len(username) < 2:
                return self._error("用户名至少 2 个字符")
            if len(username) > 20:
                return self._error("用户名不超过 20 个字符")
            if not password or len(password) < 4:
                return self._error("密码至少 4 位")
            if not username.isascii() or not username.replace("_", "").isalnum():
                return self._error("用户名只能包含字母、数字和下划线")

            user_id = create_user(username, password)
            if not user_id:
                return self._error("用户名已被注册", 409)

            token = issue_token(user_id)
            self._json({"token": token, "username": username})

        elif path == "/login":
            body = self._read_body()
            username = body.get("username", "").strip()
            password = body.get("password", "")

            user_id = verify_user(username, password)
            if not user_id:
                return self._error("用户名或密码错误", 401)

            token = issue_token(user_id)
            self._json({"token": token, "username": username})

        elif path == "/upload":
            sess = self._auth_required()
            if not sess:
                return self._error("未登录或 token 已过期", 401)

            body = self._read_body()
            save_user_data(sess["user_id"], body)
            self._json({"status": "ok", "username": sess["username"]})

        elif path == "/ping":
            sess = self._auth_required()
            if not sess:
                return self._error("未登录或 token 已过期", 401)

            update_ping(sess["user_id"])
            self._json({"status": "ok", "username": sess["username"]})

        else:
            self._error("未知路径", 404)

    def do_GET(self):
        path = self.path.rstrip("/")

        if path == "/download":
            sess = self._auth_required()
            if not sess:
                return self._error("未登录或 token 已过期", 401)

            data = get_user_data(sess["user_id"])
            data["username"] = sess["username"]

            # 管理员额外返回服务器统计
            if sess["username"].lower() == ADMIN_USERNAME:
                data["_admin"] = get_admin_stats()

            self._json(data)

        else:
            self._error("未知路径", 404)

    def log_message(self, format, *args):
        print(f"  [{datetime.now().strftime('%H:%M:%S')}] {args[0]} {args[1]} {args[2]}")


# ─── 启动 ───────────────────────────────────────────────

def run_server():
    get_db().close()
    print(f"👤 TrophyRoom Auth Server")
    print(f"   地址: http://{HOST}:{PORT}")
    print(f"   数据库: {DB_PATH}")
    print(f"   管理员: {ADMIN_USERNAME}")
    print(f"   POST /api/auth/register")
    print(f"   POST /api/auth/login")
    print(f"   POST /api/auth/upload  (需 Bearer token)")
    print(f"   POST /api/auth/ping    (需 Bearer token)")
    print(f"   GET  /api/auth/download (需 Bearer token, 管理员含统计)")
    server = HTTPServer((HOST, PORT), AuthHTTPHandler)
    server.serve_forever()


if __name__ == "__main__":
    run_server()
