// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

// Match the Highlight interface used by Kickoff's app/category delegates.
Rectangle {
    property bool hovered: ListView.view !== null || GridView.view !== null
    property bool pressed: false
    property bool active: true

    radius: Kirigami.Units.cornerRadius
    color: Qt.alpha(kickoff.launcherAccent,
                   pressed ? Math.min(1, kickoff.launcherSelectionOpacity + 0.12)
                           : kickoff.launcherSelectionOpacity)
    border.width: 1
    border.color: Qt.alpha(kickoff.launcherAccent, active ? 0.65 : 0.35)
}
