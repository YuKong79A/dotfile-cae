import QtQuick
import QtQuick.Controls
import "theme_config.js" as Config

Item {
    id: root
    width: 1920
    height: 1080

    Image {
        id: bg
        anchors.fill: parent
        source: "file:///" + Config.bgPath
    }

    Item {
        id: nexusWindow
        width: 1200
        height: 800
        anchors.centerIn: parent

        Text {
            anchors.top: parent.top
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.leftMargin: 30
            text: "Select Operating System"
            color: Config.scheme.text || "#dce8e6"
            font.pixelSize: 28
            font.bold: true
        }

        Rectangle {
            x: 20
            y: 90
            width: 1160
            height: 620
            radius: 12
            color: Config.scheme.surfaceContainerLow || "#0e1514"
            opacity: Config.layersTransparency || 0.4
        }

        Column {
            x: 30
            y: 100
            width: 1140
            spacing: typeof Config.itemSpacing !== 'undefined' ? Config.itemSpacing : 14
            visible: typeof Config.previewMode !== 'undefined' ? Config.previewMode : false

            Repeater {
                model: [
                    { text: "Arch Linux", selected: true },
                    { text: "Arch Linux 的高级选项", selected: false },
                    { text: "UEFI Firmware Settings", selected: false },
                    { text: "Arch Linux snapshots", selected: false }
                ]

                Rectangle {
                    width: parent.width
                    height: (typeof Config.itemHeight !== 'undefined' ? Config.itemHeight : 36) + ((typeof Config.itemPadding !== 'undefined' ? Config.itemPadding : 4) * 2)
                    radius: 12
                    color: Qt.alpha(modelData.selected ? (Config.scheme.surfaceContainerHighest || "#1d2827") : (Config.scheme.surfaceContainerHigh || "#192120"), Config.layersTransparency || 0.4)

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        color: modelData.selected ? (Config.scheme.text || "#dce8e6") : (Config.scheme.textDark || "#a2adac")
                        font.pixelSize: 22
                        font.family: "Google Sans Flex"
                    }
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Repeater {
                model: [
                    { key: "↑/↓", action: "Navigate" },
                    { key: "Enter", action: "Boot" },
                    { key: "E", action: "Edit" },
                    { key: "C", action: "Command" }
                ]

                Rectangle {
                    width: hintRow.width + 30
                    height: 36
                    radius: 18
                    color: Qt.alpha(Config.scheme.primaryContainer || "#255b58", Config.layersTransparency || 0.4)

                    Row {
                        id: hintRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: keyText.width + 16
                            height: 24
                            radius: 6
                            color: Qt.alpha(Config.scheme.primary || "#9bd0cc", Config.layersTransparency || 0.4)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: modelData.key
                                color: Config.scheme.onPrimary || "#0d4845"
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "sans-serif"
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.action
                            color: Config.scheme.onPrimaryContainer || "#b8ede9"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
