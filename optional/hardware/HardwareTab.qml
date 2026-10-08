import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    property var hardware: ({ fan: {}, power: {}, scx: {}, rgb: {}, errors: {} })
    property string message: ""
    property bool changing: false
    property string pendingPreset: ""
    property bool refreshAfterStatus: false

    readonly property string currentPreset: {
        const power = hardware.power.profile;
        const mode = hardware.scx.mode;
        if (power === "power-saver" && mode === "PowerSave") return "eco";
        if (power === "balanced" && mode === "Auto") return "daily";
        if (power === "performance" && mode === "Gaming") return "gaming";
        return "";
    }
    readonly property string displayedPreset: pendingPreset || currentPreset

    implicitWidth: 840
    implicitHeight: content.implicitHeight

    function refresh() {
        if (statusProc.running)
            refreshAfterStatus = true;
        else
            statusProc.running = true;
    }

    function setValue(category, value) {
        if (changing)
            return;
        changing = true;
        pendingPreset = category === "preset" ? value : "";
        message = pendingPreset ? qsTr("Applying %1...").arg(value) : "";
        actionProc.command = [Paths.home + "/.local/bin/caelestia-hardware", "set", category, value];
        actionProc.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 12000
        repeat: true
        running: true
        onTriggered: {
            if (!root.changing)
                root.refresh();
        }
    }

    Process {
        id: statusProc
        command: [Paths.home + "/.local/bin/caelestia-hardware", "status"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            try {
                if (code !== 0)
                    throw new Error(stderr.text || stdout.text);
                root.hardware = JSON.parse(stdout.text);
                if (!root.changing && root.pendingPreset !== "") {
                    root.pendingPreset = "";
                    root.message = "";
                }
            } catch (e) {
                root.message = qsTr("Could not read hardware status: %1").arg(e);
            }
            if (root.refreshAfterStatus) {
                root.refreshAfterStatus = false;
                Qt.callLater(() => root.refresh());
            }
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            root.changing = false;
            if (code !== 0) {
                root.pendingPreset = "";
                try {
                    root.message = JSON.parse(stdout.text).error;
                } catch (e) {
                    root.message = stderr.text || qsTr("Hardware command failed");
                }
            }
            root.refresh();
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            FanStatCard {
                Layout.fillWidth: true
                title: qsTr("CPU Fan Speed")
                rpm: root.hardware.fan.rpm1 ?? null
            }

            FanStatCard {
                Layout.fillWidth: true
                title: qsTr("GPU Fan Speed")
                rpm: root.hardware.fan.rpm2 ?? null
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 112
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Fan Preset Control")
                        font: Tokens.font.title.medium
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: [
                                { icon: "autorenew", label: qsTr("Auto"), value: "auto" },
                                { icon: "tune", label: qsTr("Custom"), value: "custom" },
                                { icon: "bolt", label: qsTr("Maximum"), value: "max" }
                            ]

                            ModeButton {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: index === 0
                                iconName: modelData.icon
                                label: modelData.label
                                selected: root.hardware.fan.mode === modelData.value
                                enabledAction: !root.hardware.errors.fan
                                onClicked: root.setValue("fan", modelData.value)
                            }
                        }
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 112
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Power & Thermal Profile")
                        font: Tokens.font.title.medium
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: [
                                { icon: "eco", label: qsTr("Eco"), value: "eco" },
                                { icon: "balance", label: qsTr("Daily"), value: "daily" },
                                { icon: "sports_esports", label: qsTr("Gaming"), value: "gaming" }
                            ]

                            ModeButton {
                                required property var modelData
                                Layout.fillWidth: true
                                iconName: modelData.icon
                                label: modelData.label
                                showLabel: true
                                selected: root.displayedPreset === modelData.value
                                enabledAction: root.presetsAvailable
                                onClicked: root.setValue("preset", modelData.value)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 132
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Keyboard Backlight")
                            font: Tokens.font.title.medium
                        }

                        StyledText {
                            text: root.hardware.rgb.power ? qsTr("On") : qsTr("Off")
                            font: Tokens.font.title.medium
                            color: Colours.palette.m3primary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: [
                                { label: qsTr("Off"), value: "off" },
                                { label: qsTr("On"), value: "on" }
                            ]

                            ModeButton {
                                required property var modelData
                                Layout.fillWidth: true
                                iconName: "keyboard"
                                label: modelData.label
                                showLabel: true
                                selected: (root.hardware.rgb.power ? "on" : "off") === modelData.value
                                enabledAction: !root.hardware.errors.rgb && root.hardware.rgb.available === true
                                onClicked: root.setValue("rgb", modelData.value)
                            }
                        }
                    }
                }
            }

            ButtonBase {
                Layout.preferredWidth: 108
                implicitWidth: 108
                implicitHeight: 132
                checked: false
                disabled: root.changing || statusProc.running
                activeColour: Colours.palette.m3primary
                inactiveColour: Colours.tPalette.m3surfaceContainer
                activeOnColour: Colours.palette.m3onPrimary
                inactiveOnColour: Colours.palette.m3onSurface
                radiusMorph: false
                radius: Tokens.rounding.extraLarge
                onClicked: root.refresh()

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "refresh"
                        fontStyle: Tokens.font.icon.large
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Refresh")
                        font: Tokens.font.body.medium
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.message !== ""
            text: root.message
            font: Tokens.font.body.small
            color: Colours.palette.m3error
            wrapMode: Text.Wrap
        }
    }

    readonly property bool presetsAvailable: !hardware.errors.power && !hardware.errors.scx && !hardware.errors.fan && hardware.power.available === true && hardware.scx.scheduler === "lavd"

    component FanStatCard: StyledRect {
        required property string title
        required property var rpm

        implicitHeight: 100
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            StyledRect {
                implicitWidth: 58
                implicitHeight: 58
                radius: Tokens.rounding.medium
                color: Colours.palette.m3primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "mode_fan"
                    fontStyle: Tokens.font.icon.large
                    color: Colours.palette.m3onPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: title
                    font: Tokens.font.title.medium
                }

                StyledText {
                    text: rpm == null ? "— RPM" : rpm + " RPM"
                    font: Tokens.font.headline.medium
                }
            }
        }
    }

    component ModeButton: ButtonBase {
        id: button

        required property string iconName
        required property string label
        property bool selected: false
        property bool enabledAction: true
        property bool showLabel: false

        implicitWidth: selected || showLabel ? 116 : 44
        implicitHeight: 44
        checked: selected
        disabled: !enabledAction || root.changing
        activeColour: Colours.palette.m3primaryContainer
        inactiveColour: Colours.tPalette.m3surfaceContainerHigh
        activeOnColour: Colours.palette.m3onPrimaryContainer
        inactiveOnColour: Colours.palette.m3onSurface
        radiusMorph: false

        RowLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: button.iconName
                fontStyle: Tokens.font.icon.small
                color: button.onColour
            }

            StyledText {
                visible: button.selected || button.showLabel
                text: button.label
                font: Tokens.font.body.medium
                color: button.onColour
            }
        }
    }
}
