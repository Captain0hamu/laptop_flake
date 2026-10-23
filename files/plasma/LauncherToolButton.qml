// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

PC3.ToolButton {
    id: control
    background: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 2
        implicitHeight: Kirigami.Units.gridUnit * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(kickoff.launcherAccent,
                       control.down ? kickoff.launcherSelectionOpacity + 0.12
                       : control.hovered || control.checked || control.visualFocus
                         ? kickoff.launcherSelectionOpacity : 0)
        border.width: control.visualFocus ? 1 : 0
        border.color: kickoff.launcherAccent
    }
}
