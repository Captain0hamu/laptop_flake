#!/usr/bin/env python3
"""Check the lock-screen patch and its authentication-success branches."""

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "files/plasma/patch-lockscreen.py"

# The relevant structure of Plasma 6.8's LockScreenUi.qml.
UPSTREAM = '''Item {
    id: lockScreenUi
    Connections {
        function onFailed(kind) {
        }
        function onSucceeded() {
            authenticator.stopAuthenticating()

            if (!lockScreenUi.expectingPrompt) {
                Qt.quit()
            }
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                mainStack.replace(null, Qt.resolvedUrl("NoPasswordUnlock.qml"),
                    { userListModel: users }, StackView.Immediate);
                mainStack.forceActiveFocus();
            }
        }

        function onInfoMessageChanged() {
        }
    }
    SessionManagement {
    }
    MouseArea {
        id: lockScreenRoot
        WallpaperFader {
            anchors.fill: parent
        }
                showUserList: userList.y + mainStack.y > 0
    }
}
'''


class LockscreenPatchTest(unittest.TestCase):
    def test_success_paths(self):
        if not shutil.which("node"):
            self.skipTest("node is required to exercise the QML JavaScript")
        with tempfile.TemporaryDirectory() as directory:
            qml = Path(directory) / "LockScreenUi.qml"
            qml.write_text(UPSTREAM)
            subprocess.run(["python3", str(PATCH), str(qml)], check=True)
            text = qml.read_text()
            self.assertIn("if (lockScreenUi.entering) return;", text)
            handler = text.split("        function onSucceeded() {", 1)[1].split(
                "\n        function onInfoMessageChanged()", 1
            )[0].rsplit("\n        }", 1)[0]
            script = '''
const assert = require("assert");
const run = new Function("lockScreenUi", "authenticator", "unlockTransition",
    "mainStack", "Qt", "users", "StackView", process.argv[1]);
for (const expectingPrompt of [false, true]) {
    for (const hadPrompt of [false, true]) {
        const ui = { expectingPrompt, entering: false };
        let stopped = 0, started = 0, replaced = 0, focused = 0;
        const shouldUnlock = !expectingPrompt || hadPrompt;
        const authenticator = { hadPrompt, stopAuthenticating() {
            assert.strictEqual(ui.entering, shouldUnlock);
            stopped++;
        }};
        run(ui, authenticator, { start() { started++; } },
            { replace() { replaced++; }, forceActiveFocus() { focused++; } },
            { quit() { throw new Error("unexpected immediate quit"); }, resolvedUrl(x) { return x; } },
            {}, { Immediate: 0 });
        assert.strictEqual(stopped, 1);
        assert.strictEqual(started, Number(shouldUnlock));
        assert.strictEqual(replaced, Number(!shouldUnlock));
        assert.strictEqual(focused, Number(!shouldUnlock));
    }
}
'''
            subprocess.run(["node", "-e", script, handler], check=True)


if __name__ == "__main__":
    unittest.main()
