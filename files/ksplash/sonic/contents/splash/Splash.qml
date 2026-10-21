import QtQuick
import "anim/frames.js" as FrameData

Item {
    id: root

    property int stage: 0
    property int frameIndex: 0
    property int readyCount: 0
    readonly property int frameDuration: 140
    readonly property int fadeDuration: 360
    readonly property var frames: FrameData.frames

    Repeater {
        model: root.frames

        Image {
            anchors.fill: parent
            source: "anim/" + modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: root.width
            sourceSize.height: root.height
            opacity: index === root.frameIndex ? 1 : 0
            visible: opacity > 0

            onStatusChanged: if (status === Image.Ready) root.readyCount++

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.12
    }

    Image {
        anchors.fill: parent
        source: "anim/scanlines.png"
        fillMode: Image.Tile
        opacity: 0.14
    }

    Timer {
        id: frameTimer
        interval: root.frameDuration
        running: root.readyCount >= root.frames.length
        repeat: true
        onTriggered: {
            if (root.frameIndex < root.frames.length - 1) {
                root.frameIndex++;
            } else {
                frameTimer.running = false;
                fadeOut.start();
            }
        }
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "opacity"
        to: 0
        duration: root.fadeDuration
        easing.type: Easing.InOutQuad
        onFinished: Qt.quit()
    }
}
