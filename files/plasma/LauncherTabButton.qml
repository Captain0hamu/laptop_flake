// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

PC3.TabButton {
    id: control
    // The selected tab's fill is drawn by Footer's ListView highlight.
    background: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 2
        implicitHeight: Kirigami.Units.gridUnit * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(kickoff.launcherAccent,
                       control.hovered && !control.checked ? kickoff.launcherSelectionOpacity : 0)
        border.width: control.visualFocus ? 1 : 0
        border.color: kickoff.launcherAccent
    }
}
