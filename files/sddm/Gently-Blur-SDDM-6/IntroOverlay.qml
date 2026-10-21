import QtQuick 2.15

Item {
    id: root

    opacity: 1
    visible: opacity > 0

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.45
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.34
        opacity: 0.55
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#cc000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    Column {
        id: titleBlock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.30
        spacing: 2

        Item {
            id: titleItem
            width: title.implicitWidth
            height: title.implicitHeight

            Text {
                id: titleRed
                x: 2
                y: 0
                text: "GRAND THEFT GENTOO"
                color: "#e06c75"
                opacity: 0.35
                font.family: "BankGothic"
                font.pixelSize: Math.round(root.height * 0.056)
                font.letterSpacing: 5
            }

            Text {
                id: titleCyan
                x: -2
                y: 0
                text: titleRed.text
                color: "#56b6c2"
                opacity: 0.35
                font.family: "BankGothic"
                font.pixelSize: titleRed.font.pixelSize
                font.letterSpacing: 5
            }

            Text {
                id: title
                x: 0
                y: 0
                text: titleRed.text
                color: "#e6edf5"
                font.family: "BankGothic"
                font.pixelSize: titleRed.font.pixelSize
                font.letterSpacing: 5
            }
        }

        Text {
            id: subtitle
            width: titleItem.width
            horizontalAlignment: Text.AlignHCenter
            text: "SYSTEM READY // WELCOME BACK"
            color: "#8fb3d9"
            font.family: "DejaVu Sans"
            font.pixelSize: Math.round(root.height * 0.016)
            font.letterSpacing: 3
        }
    }

    Row {
        id: loadingLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.80
        spacing: 10

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: "#e06c75"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "LOADING SESSION"
            color: "#a9c9ef"
            font.family: "DejaVu Sans"
            font.pixelSize: Math.round(root.height * 0.014)
            font.letterSpacing: 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.855
        width: Math.round(parent.width * 0.22)
        height: 3
        color: "#1a2733"
        radius: 1.5

        Rectangle {
            height: parent.height
            color: "#8fb3d9"
            radius: 1.5

            NumberAnimation on width {
                from: 0
                to: parent.width
                duration: 2200
                easing.type: Easing.InOutQuad
            }
        }
    }

    Timer {
        interval: 2400
        running: true
        onTriggered: fadeOut.start()
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "opacity"
        to: 0
        duration: 700
        easing.type: Easing.InOutQuad
    }
}
