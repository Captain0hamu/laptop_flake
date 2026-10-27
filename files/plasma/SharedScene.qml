import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: scene
    property bool showClock: true
    property bool entering: false
    property bool fadeOnEnter: true
    property date now: new Date()

    // Identical animated source and framing on the lock and startup screens.
    AnimatedBackground {
        id: backdrop
        anchors.fill: parent
    }
    FastBlur {
        anchors.fill: parent
        source: backdrop
        radius: 24
        opacity: 0.85
    }

    // A frosted veil keeps text readable without blurring the password field.
    Rectangle {
        anchors.fill: parent
        color: "#151c2c"
        opacity: 0.32
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(20, Math.min(parent.width, parent.height) * 0.035)
        color: "transparent"
        radius: 24
        border.color: "#77a9c9ef"
        border.width: 1
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.08
        width: Math.min(420, parent.width * 0.8)
        height: 2
        color: "#a9c9ef"
        opacity: 0.7
    }

    Column {
        visible: scene.showClock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.14
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(scene.now, "hh:mm")
            color: "white"
            font.pixelSize: Math.max(48, Math.min(scene.height * 0.105, 110))
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(scene.now, Qt.DefaultLocaleLongDate)
            color: "#d7e5f5"
            font.pixelSize: 18
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: scene.now = new Date()
    }

    transform: Scale {
        origin.x: scene.width / 2
        origin.y: scene.height / 2
        xScale: scene.entering ? 2.0 : 1.0
        yScale: scene.entering ? 2.0 : 1.0
        Behavior on xScale { NumberAnimation { duration: 850; easing.type: Easing.InCubic } }
        Behavior on yScale { NumberAnimation { duration: 850; easing.type: Easing.InCubic } }
    }
    opacity: entering && fadeOnEnter ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 850; easing.type: Easing.InCubic } }
}
