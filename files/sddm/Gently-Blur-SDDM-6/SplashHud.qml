import QtQuick 2.15

Item {
    id: root

    width: 430
    height: 116

    readonly property var tracks: [
        "emerge --sync",
        "have you tried rebooting?",
        "sudo make me a sandwich",
        "GNU is Not Unix",
        "it works on my machine",
        "git push --force",
        "docker run --privileged",
        "segfault (feat. core dump)",
        "tabs vs spaces",
        "kill -9",
        "it's always DNS"
    ]

    property int trackIndex: 0

    Rectangle {
        anchors.fill: parent
        color: "#070a0d"
        opacity: 0.78
        radius: 10
        border.width: 1
        border.color: "#475a6b"
    }

    Rectangle {
        x: 12
        y: 18
        width: 4
        height: parent.height - 36
        color: "#a9c9ef"
        radius: 2
    }

    Text {
        x: 30
        y: 15
        text: "RADIO GENTOO"
        color: "#a9c9ef"
        font.family: "BankGothic"
        font.pixelSize: 25
        font.letterSpacing: 2
    }

    Text {
        x: 31
        y: 48
        text: "101.3 FM // BOOT SEQUENCE"
        color: "#8fb3d9"
        font.family: "DejaVu Sans"
        font.pixelSize: 12
        font.letterSpacing: 1
    }

    Rectangle {
        x: parent.width - 92
        y: 19
        width: 7
        height: 7
        radius: 3.5
        color: "#e06c75"

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.35; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.0; to: 0.35; duration: 700; easing.type: Easing.InOutSine }
        }
    }

    Text {
        x: parent.width - 78
        y: 13
        text: "ON AIR"
        color: "#e06c75"
        font.family: "DejaVu Sans"
        font.pixelSize: 11
        font.letterSpacing: 1
    }

    Text {
        x: 30
        y: 73
        text: "NOW PLAYING:"
        color: "#6f8fae"
        font.family: "DejaVu Sans"
        font.pixelSize: 11
        font.letterSpacing: 1
    }

    Text {
        x: 118
        y: 69
        width: parent.width - 136
        text: root.tracks[root.trackIndex]
        color: "#e6edf5"
        font.family: "DejaVu Sans"
        font.pixelSize: 15
        elide: Text.ElideRight
    }

    Rectangle {
        x: 30
        y: 100
        width: parent.width - 60
        height: 4
        color: "#1a2733"
        radius: 2

        Rectangle {
            height: parent.height
            color: "#8fb3d9"
            radius: 2

            NumberAnimation on width {
                from: 8
                to: root.width - 60
                duration: 22000
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
            }
        }
    }

    Timer {
        interval: 4200
        repeat: true
        running: true
        onTriggered: root.trackIndex = (root.trackIndex + 1) % root.tracks.length
    }
}
