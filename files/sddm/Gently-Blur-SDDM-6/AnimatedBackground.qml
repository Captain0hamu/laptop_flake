import QtQuick 2.15
import "anim/frames.js" as FrameData

Item {
    id: root

    anchors.fill: parent

    readonly property int frameCount: FrameData.frames.length
    readonly property int frameDuration: 620

    property real progress: 0
    readonly property int baseIndex: Math.floor(progress) % frameCount
    readonly property int nextIndex: (baseIndex + 1) % frameCount
    readonly property real blend: progress - Math.floor(progress)

    Item {
        id: stage
        width: root.width
        height: root.height
        scale: 1.06

        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 1.035; to: 1.095; duration: 16000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.095; to: 1.035; duration: 16000; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on x {
            loops: Animation.Infinite
            PauseAnimation { duration: 700 }
            NumberAnimation { from: -root.width * 0.008; to: root.width * 0.008; duration: 19000; easing.type: Easing.InOutSine }
            NumberAnimation { from: root.width * 0.008; to: -root.width * 0.008; duration: 19000; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on y {
            loops: Animation.Infinite
            PauseAnimation { duration: 400 }
            NumberAnimation { from: -root.height * 0.005; to: root.height * 0.005; duration: 23000; easing.type: Easing.InOutSine }
            NumberAnimation { from: root.height * 0.005; to: -root.height * 0.005; duration: 23000; easing.type: Easing.InOutSine }
        }

        Repeater {
            model: FrameData.frames

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: true
                source: "anim/" + modelData
                sourceSize.width: root.width
                sourceSize.height: root.height
                opacity: index === root.baseIndex
                    ? 1 - root.blend
                    : (index === root.nextIndex ? root.blend : 0)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.16
    }

    Image {
        anchors.fill: parent
        source: "anim/scanlines.png"
        fillMode: Image.Tile
        opacity: 0.14
    }

    Rectangle {
        id: scanBand
        width: parent.width
        height: parent.height * 0.16
        y: -height
        opacity: 0.05
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.5; color: "#cfe3ff" }
            GradientStop { position: 1.0; color: "#00000000" }
        }

        NumberAnimation on y {
            from: -scanBand.height
            to: root.height
            duration: 5200
            loops: Animation.Infinite
            easing.type: Easing.Linear
        }
    }

    Repeater {
        model: 16

        Rectangle {
            readonly property real travel: 700 + Math.random() * 1600

            width: 40 + Math.random() * 180
            height: 1 + Math.random() * 2
            y: Math.random() * root.height
            color: "#cfe3ff"
            opacity: 0.04 + Math.random() * 0.10
            radius: height / 2
            x: root.width + width

            SequentialAnimation on x {
                loops: Animation.Infinite
                PauseAnimation { duration: Math.random() * 2400 }
                NumberAnimation {
                    from: root.width + 10
                    to: -width - 10
                    duration: travel
                    easing.type: Easing.Linear
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.42
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#aa000000" }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.22
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#88000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    Rectangle {
        id: flash
        anchors.fill: parent
        color: "#cfe3ff"
        opacity: 0
    }

    NumberAnimation {
        id: flashAnim
        target: flash
        property: "opacity"
        from: 0.08
        to: 0
        duration: 220
        easing.type: Easing.OutQuad
    }

    NumberAnimation on progress {
        from: 0
        to: root.frameCount
        duration: root.frameCount * root.frameDuration
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    onBaseIndexChanged: {
        if (baseIndex !== 0 && baseIndex % 4 === 0) {
            flash.opacity = 0.08;
            flashAnim.restart();
        }
    }
}
