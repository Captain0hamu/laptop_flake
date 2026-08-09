/*
    Minimal Breeze-derived SDDM layout with centered login controls.
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami 2.20 as Kirigami

import org.kde.breeze.components

Item {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    width: 1600
    height: 900

    property string notificationMessage: ""

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: screenModel

            Background {
                x: geometry.x
                y: geometry.y
                width: geometry.width
                height: geometry.height
                sceneBackgroundType: config.type
                sceneBackgroundColor: config.color
                sceneBackgroundImage: config.background
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#12000000"
    }

    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: loginPanel
    }

    Item {
        id: loginPanel
        anchors.centerIn: parent
        width: 1
        height: 1
        focus: true

        property bool showUsernamePrompt: false
        property Item mainPasswordBox: passwordBox

        Timer {
            running: true
            repeat: false
            interval: 200
            onTriggered: {
                if (loginPanel.showUsernamePrompt) {
                    usernameInput.forceActiveFocus()
                } else {
                    passwordInput.forceActiveFocus()
                }
            }
        }

        Rectangle {
            id: userIcon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Kirigami.Units.gridUnit * 6
            width: Kirigami.Units.gridUnit * 6
            height: Kirigami.Units.gridUnit * 6
            radius: width / 2
            color: "#00000000"
            border.color: "#e8e8e8"
            border.width: 3

            Rectangle {
                width: parent.width * 0.26
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.18
                color: "#e8e8e8"
            }

            Item {
                width: parent.width * 0.58
                height: parent.height * 0.34
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.12

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#e8e8e8"
                }

                Rectangle {
                    width: parent.width * 0.7
                    height: parent.height * 0.65
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    color: "#e8e8e8"
                }
            }
        }

        Text {
            id: userLabel
            anchors.top: userIcon.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            text: loginPanel.showUsernamePrompt ? i18nd("plasma-desktop-sddm-theme", "Sign in") : userModel.lastUser
            font.pixelSize: 22
            color: "#f5f5f5"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            id: messageLabel
            anchors.top: userLabel.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            visible: capsLockState.locked || !!root.notificationMessage
            text: {
                const parts = []
                if (capsLockState.locked) {
                    parts.push(i18nd("plasma-desktop-sddm-theme", "Caps Lock is on"))
                }
                if (root.notificationMessage) {
                    parts.push(root.notificationMessage)
                }
                return parts.join(" • ")
            }
            color: "#f3d7d7"
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: usernameField
            width: Math.min(root.width - Kirigami.Units.gridUnit * 8, 320)
            anchors.top: messageLabel.visible ? messageLabel.bottom : userLabel.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            visible: loginPanel.showUsernamePrompt
            height: 44
            radius: 10
            color: "#f6f6f6"

            TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.margins: 12
                text: userModel.lastUser
                color: "#111111"
                selectionColor: "#606060"
                selectedTextColor: "#ffffff"
                font.pixelSize: 18
                verticalAlignment: TextInput.AlignVCenter
                onAccepted: passwordInput.forceActiveFocus()
            }
        }

        RowLayout {
            id: passwordRow
            width: Math.min(root.width - Kirigami.Units.gridUnit * 8, 320)
            anchors.top: loginPanel.showUsernamePrompt ? usernameField.bottom : (messageLabel.visible ? messageLabel.bottom : userLabel.bottom)
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: "#f6f6f6"

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 12
                    color: "#111111"
                    selectionColor: "#606060"
                    selectedTextColor: "#ffffff"
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    onAccepted: loginButton.clicked()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passwordInput.length === 0 && !passwordInput.activeFocus
                    text: i18nd("plasma-desktop-sddm-theme", "Password")
                    color: "#7a7a7a"
                    font.pixelSize: 18
                }

                Connections {
                    target: sddm

                    function onLoginFailed() {
                        passwordInput.selectAll()
                        passwordInput.forceActiveFocus()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                id: loginButton
                Layout.preferredHeight: 44
                Layout.preferredWidth: 44
                radius: 10
                color: "#f6f6f6"

                Text {
                    anchors.centerIn: parent
                    text: root.LayoutMirroring.enabled ? "←" : "→"
                    color: "#111111"
                    font.pixelSize: 22
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: loginButton.clicked()
                }

                signal clicked()
                onClicked: {
                    root.notificationMessage = ""
                    loginPanel.enabled = false
                    sddm.login(loginPanel.showUsernamePrompt ? usernameInput.text : userModel.lastUser,
                               passwordInput.text,
                               sessionButton.currentIndex)
                }
            }
        }

        RowLayout {
            id: actionRow
            anchors.top: passwordRow.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    {
                        icon: loginPanel.showUsernamePrompt ? "≡" : "⌘",
                        label: loginPanel.showUsernamePrompt
                            ? i18nd("plasma-desktop-sddm-theme", "Back")
                            : i18ndc("plasma-desktop-sddm-theme", "For switching to a username and password prompt", "Switch User"),
                        enabled: true,
                        action: function() {
                            loginPanel.showUsernamePrompt = !loginPanel.showUsernamePrompt
                            root.notificationMessage = ""
                            passwordInput.text = ""
                            if (loginPanel.showUsernamePrompt) {
                                usernameInput.forceActiveFocus()
                            } else {
                                passwordInput.forceActiveFocus()
                            }
                        }
                    },
                    {
                        icon: "↻",
                        label: i18nd("plasma-desktop-sddm-theme", "Restart"),
                        enabled: sddm.canReboot,
                        action: function() { sddm.reboot() }
                    },
                    {
                        icon: "⏻",
                        label: i18nd("plasma-desktop-sddm-theme", "Shut Down"),
                        enabled: sddm.canPowerOff,
                        action: function() { sddm.powerOff() }
                    }
                ]

                delegate: Item {
                    width: 88
                    height: 84
                    enabled: modelData.enabled
                    opacity: enabled ? 1 : 0.45

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#20ffffff"
                        border.color: "#55ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: "#f5f5f5"
                            font.pixelSize: 22
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 54
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: "#f5f5f5"
                        font.pixelSize: 15
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.enabled
                        onClicked: modelData.action()
                    }
                }
            }
        }
    }

    VirtualKeyboardLoader {
        id: inputPanel
        z: 1
        screenRoot: root
        mainStack: loginPanel
        mainBlock: loginPanel
        passwordField: passwordInput
    }

    Item {
        id: footer
        enabled: true
        visible: false
        opacity: 0
    }

    SessionButton {
        id: sessionButton
        visible: false
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.notificationMessage = i18nd("plasma-desktop-sddm-theme", "Login Failed")
            footer.enabled = true
            loginPanel.enabled = true
            rejectPasswordAnimation.start()
        }

        function onLoginSucceeded() {
            loginPanel.opacity = 0
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.restart()
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: root.notificationMessage = ""
    }
}
