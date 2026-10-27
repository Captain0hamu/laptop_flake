"""Patch Plasma's own lock UI, retaining its PAM, fingerprint and session controls."""

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()


def replace_once(before, after):
    global text
    if text.count(before) != 1:
        raise ValueError(f"Plasma lockscreen changed: expected one {before!r}")
    text = text.replace(before, after)


replace_once('    id: lockScreenUi\n', '''    id: lockScreenUi
    property bool entering: false
    SharedScene {
        anchors.fill: parent
        showClock: false // Plasma's native clock keeps the password layout intact.
        fadeOnEnter: false // Keep the underlying wallpaper hidden until unlock.
        entering: lockScreenUi.entering
    }
''')
replace_once('''        function onFailed(kind) {
''', '''        function onFailed(kind) {
            if (lockScreenUi.entering) return;
''')
replace_once('''            authenticator.stopAuthenticating()
''', '''            // Stopping PAM can itself emit a failure; mark success first.
            // RejectPasswordAnimation exposes start(), but not stop().
            if (authenticator.hadPrompt) {
                lockScreenUi.entering = true;
            }
            authenticator.stopAuthenticating()
''')
replace_once('''            if (authenticator.hadPrompt) {
                Qt.quit();
''', '''            if (authenticator.hadPrompt) {
                unlockTransition.start();
''')
replace_once('    SessionManagement {\n', '''    Timer {
        id: unlockTransition
        interval: 850
        onTriggered: Qt.quit()
    }

    SessionManagement {
''')
replace_once('''        WallpaperFader {
            anchors.fill: parent
''', '''        WallpaperFader {
            // Keep its state transitions for the clock and controls, but don't
            // paint Plasma's wallpaper over the animated scene.
            opacity: 0
            anchors.fill: parent
''')
replace_once('''    MouseArea {
        id: lockScreenRoot
''', '''    MouseArea {
        id: lockScreenRoot
        opacity: lockScreenUi.entering ? 0 : 1
        scale: lockScreenUi.entering ? 0.7 : 1
        Behavior on opacity { NumberAnimation { duration: 750 } }
        Behavior on scale { NumberAnimation { duration: 750; easing.type: Easing.InCubic } }
''')
path.write_text(text)
