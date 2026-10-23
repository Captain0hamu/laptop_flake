import QtQuick

Item {
    id: root
    width: 1600
    height: 900
    property int stage

    SharedScene {
        id: scene
        anchors.fill: parent
    }

    // KSplash calls stage 1 at startup and stage 5 when Plasma is ready.
    onStageChanged: if (stage >= 5) scene.entering = true
}
