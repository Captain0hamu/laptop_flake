import QtQuick
import "anim/frames.js" as FrameData

Item {
    id: root

    property int stage: 0
    property int frameIndex: 0
    readonly property int frameDuration: 620
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

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
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
        interval: root.frameDuration
        running: true
        repeat: true
        onTriggered: root.frameIndex = (root.frameIndex + 1) % root.frames.length
    }
}
