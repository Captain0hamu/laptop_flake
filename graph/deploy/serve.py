#!/usr/bin/env python3
"""Serve only the published snapshot; never follow links outside it."""
import http.server
import os
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(os.environ.get("SHOWCASE_HOME", Path.home() / ".local/share/nixos-showcase")) / "current"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        if urlsplit(self.path).path == "/":
            self.send_response(302)
            self.send_header("Location", "/graph/showcase.html")
            self.end_headers()
            return
        super().do_GET()

    def send_head(self):
        parts = unquote(urlsplit(self.path).path).split("/")
        if any(part in ("..", ".") or part.startswith(".") for part in parts if part):
            self.send_error(404)
            return None
        root = ROOT.resolve()
        target = Path(self.translate_path(self.path)).resolve()
        if not target.is_relative_to(root) or not parts[1:2] or parts[1] not in ("graph", "files"):
            self.send_error(404)
            return None
        return super().send_head()

    def list_directory(self, path):
        self.send_error(403)
        return None


http.server.ThreadingHTTPServer(("127.0.0.1", 18766), Handler).serve_forever()
