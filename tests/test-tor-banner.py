#!/usr/bin/env python3
"""Exercise Tor banners in real pseudo-terminals of different sizes."""

import fcntl
import os
from pathlib import Path
import pty
import re
import struct
import subprocess
import termios
import unittest

ROOT = Path(__file__).resolve().parents[1]
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def banner(columns, rows, mode="shell", no_color=True):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
    env = {**os.environ, "TERM": "xterm-256color"}
    if no_color:
        env["NO_COLOR"] = "1"
    else:
        env.pop("NO_COLOR", None)
    try:
        process = subprocess.Popen(
            ["bash", "-c", 'source scripts/tor-banner.sh; tor-banner "$1"', "test", mode],
            cwd=ROOT, stdin=slave, stdout=slave, stderr=slave, env=env,
        )
        os.close(slave)
        slave = None
        output = bytearray()
        while True:
            try:
                part = os.read(master, 65536)
                if not part:
                    break
                output.extend(part)
            except OSError:
                break  # Linux ptys signal EOF with EIO.
        if process.wait() != 0:
            raise AssertionError(output.decode())
        return output.decode()
    finally:
        os.close(master)
        if slave is not None:
            os.close(slave)


class TorBannerTest(unittest.TestCase):
    def test_size_fallbacks_fit_and_keep_the_warning(self):
        for columns, rows in [(104, 24), (103, 24), (104, 23), (70, 15), (37, 6), (23, 3), (12, 2)]:
            with self.subTest(columns=columns, rows=rows):
                output = banner(columns, rows)
                self.assertNotIn("\x1b[", output)
                self.assertLessEqual(len(output.splitlines()), rows)
                self.assertLessEqual(max(map(len, output.splitlines()), default=0), columns)
                if columns >= 70 and rows >= 15:
                    self.assertIn("Traffic is not routed automatically.", output)

    def test_large_banner_and_start_mode(self):
        large = banner(104, 24)
        compact = banner(103, 24)
        self.assertIn("▀██████████████▀", large)
        self.assertNotIn("▀██████████████▀", compact)
        started = banner(120, 30, "start")
        self.assertIn("T O R   C L I E N T", started)
        self.assertIn("127.0.0.1:9050", started)
        self.assertIn("Wait for bootstrap to reach 100%.", started)

    def test_color_and_no_color(self):
        colored = banner(104, 24, no_color=False)
        self.assertIn("\x1b[", colored)
        self.assertEqual(ANSI.sub("", colored), banner(104, 24))


if __name__ == "__main__":
    unittest.main()
