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
        entering: lockScreenUi.entering
    }
''')
replace_once('''            if (authenticator.hadPrompt) {
                Qt.quit();
''', '''            if (authenticator.hadPrompt) {
                lockScreenUi.entering = true;
                unlockTransition.start();
''')
replace_once('    SessionManagement {\n', '''    Timer {
        id: unlockTransition
        interval: 850
        onTriggered: Qt.quit()
    }

    SessionManagement {
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
