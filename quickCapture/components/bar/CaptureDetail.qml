import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    required property var widget
    readonly property var daemon: widget.daemon
    readonly property var recorder: widget.recorder
    readonly property var config: widget.config
    readonly property bool videoMode: widget.widgetMode === "video"
    readonly property bool isRecording: widget.isRecording

    implicitHeight: contentColumn.implicitHeight

    component ModeTile: Rectangle {
        id: tile
        required property var modelData
        property int columns: 4

        signal triggered

        width: (parent.width - parent.spacing * (columns - 1)) / columns
        height: 64
        radius: Theme.cornerRadius
        color: tileArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : Theme.surfaceContainerHigh
        border.color: tileArea.containsMouse ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.shorterDuration
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.shorterDuration
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.spacingS * 2
            spacing: Theme.spacingXS

            DankIcon {
                name: tile.modelData.icon
                size: Theme.iconSize
                color: tileArea.containsMouse ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: tile.modelData.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: tileArea.containsMouse ? Font.Medium : Font.Normal
                color: tileArea.containsMouse ? Theme.primary : Theme.surfaceText
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        DankRipple {
            id: tileRipple
            anchors.fill: parent
            rippleColor: Theme.primary
            cornerRadius: tile.radius
            clip: true
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => tileRipple.trigger(mouse.x, mouse.y)
            onClicked: tile.triggered()
        }
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.spacingM

        // Segmented Mode Switcher (Screenshot vs Recording)
        Rectangle {
            width: parent.width
            height: 36
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            clip: true

            Row {
                anchors.fill: parent

                // Photo Tab
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    radius: Theme.cornerRadius
                    color: !root.videoMode ? Theme.primary : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "photo_camera"
                            size: Theme.iconSizeSmall
                            color: !root.videoMode ? Theme.onPrimary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.trFor("quickCapture", "Screenshot")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: !root.videoMode ? Font.Bold : Font.Normal
                            color: !root.videoMode ? Theme.onPrimary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.widget.setWidgetMode("photo")
                    }
                }

                // Video Tab
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    radius: Theme.cornerRadius
                    color: root.videoMode ? (root.isRecording ? Theme.error : Theme.primary) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "videocam"
                            size: Theme.iconSizeSmall
                            color: root.videoMode ? (root.isRecording ? (Theme.onError ? Theme.onError : Theme.background) : Theme.onPrimary) : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.isRecording ? I18n.trFor("quickCapture", "Recording...") : I18n.trFor("quickCapture", "Screen Recording")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.videoMode ? Font.Bold : Font.Normal
                            color: root.videoMode ? (root.isRecording ? (Theme.onError ? Theme.onError : Theme.background) : Theme.onPrimary) : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.widget.setWidgetMode("video")
                    }
                }
            }
        }

        // Photo Mode Grid
        Grid {
            visible: !root.videoMode
            width: parent.width
            columns: 4
            spacing: Theme.spacingS

            Repeater {
                model: root.config.modesFor(["region", "window", "full", "last", "scroll", "all", "clipboard", "selectFile"])

                delegate: ModeTile {
                    columns: 4
                    onTriggered: {
                        if (root.daemon)
                            root.daemon.capture(modelData.value, "edit");
                    }
                }
            }
        }

        // Video Mode - Active Recording Hero Card
        Rectangle {
            visible: root.videoMode && root.isRecording
            width: parent.width
            height: 120
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.error, 0.08)
            border.color: Theme.withAlpha(Theme.error, 0.35)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingXS

                // Top Status & Target
                Item {
                    width: parent.width
                    height: 20

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        RecordingDot {
                            dotSize: 10
                            paused: root.widget.isPaused
                            blink: root.widget.blinkRecordDot
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.widget.isPaused
                                ? I18n.trFor("quickCapture", "Recording Paused")
                                : I18n.trFor("quickCapture", "Recording...")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.widget.isPaused ? Theme.warning : Theme.error
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Format badge
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        radius: 4
                        color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.8)
                        width: formatBadgeText.implicitWidth + Theme.spacingS * 2

                        StyledText {
                            id: formatBadgeText
                            anchors.centerIn: parent
                            text: {
                                const rec = root.recorder;
                                if (!rec) return "";
                                const fmt = (rec.videoFormat || "mp4").toUpperCase();
                                const fps = fmt === "GIF" ? (rec.gifFramerate || 15) : (rec.framerate || 60);
                                return `${fmt} · ${fps} FPS`;
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            font.features: { "tnum": 1 }
                            color: Theme.surfaceVariantText
                        }
                    }
                }

                // Big Elapsed Timer
                Item {
                    width: parent.width
                    height: 40

                    StyledText {
                        anchors.centerIn: parent
                        text: root.widget.durationText
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        font.features: { "tnum": 1 }
                        color: root.widget.isPaused ? Theme.warning : Theme.error
                    }
                }

                // Transport Controls
                RecordingTransport {
                    anchors.horizontalCenter: parent.horizontalCenter
                    recorder: root.widget.recorder
                    buttonSize: 34
                    iconSize: Theme.iconSize
                    filled: true
                }
            }
        }

        // Video Mode - Idle (Ready to Record)
        Column {
            visible: root.videoMode && !root.isRecording
            width: parent.width
            spacing: Theme.spacingM

            Grid {
                width: parent.width
                columns: 3
                spacing: Theme.spacingS

                Repeater {
                    model: root.config.recordModes

                    delegate: ModeTile {
                        columns: 3
                        height: 72
                        onTriggered: {
                            if (root.daemon)
                                root.daemon.record(modelData.value);
                        }
                    }
                }
            }

            // Info strip: Format & Settings summary
            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerLow
                border.color: Theme.withAlpha(Theme.outline, 0.1)
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "tune"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: {
                            const rec = root.recorder;
                            if (!rec) return "";
                            const fmt = (rec.videoFormat || "mp4").toUpperCase();
                            const fps = fmt === "GIF" ? (rec.gifFramerate || 15) : (rec.framerate || 60);
                            return I18n.trFor("quickCapture", "Format: %1 (%2 FPS)").arg(fmt).arg(fps);
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankActionButton {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "open_in_new"
                    buttonSize: 28
                    iconSize: Theme.iconSizeSmall
                    iconColor: Theme.surfaceVariantText
                    tooltipText: I18n.trFor("quickCapture", "Recording Folder")
                    onClicked: {
                        if (root.daemon)
                            root.daemon.openFolder("video");
                    }
                }
            }
        }

        // Bottom Utility Row
        Row {
            width: parent.width
            height: 32

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DankButton {
                    buttonHeight: 32
                    iconName: "history"
                    text: I18n.trFor("quickCapture", "History")
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: {
                        if (root.daemon)
                            root.daemon.showHistoryCarousel();
                    }
                }

                DankButton {
                    buttonHeight: 32
                    iconName: "folder"
                    text: I18n.trFor("quickCapture", "Folder")
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: {
                        if (root.daemon)
                            root.daemon.openFolder(root.videoMode ? "video" : "photo");
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS

                DankActionButton {
                    readonly property bool hiding: root.daemon ? root.daemon.hideControlCenter : true
                    iconName: hiding ? "visibility_off" : "visibility"
                    buttonSize: 32
                    iconSize: Theme.iconSizeSmall
                    iconColor: hiding ? Theme.surfaceVariantText : Theme.primary
                    backgroundColor: Theme.surfaceContainerHigh
                    tooltipText: hiding ? I18n.trFor("quickCapture", "Hide Control Center") : I18n.trFor("quickCapture", "Show Control Center")
                    onClicked: {
                        if (root.daemon)
                            root.daemon.toggleHideControlCenter();
                    }
                }

                DankActionButton {
                    iconName: "settings"
                    buttonSize: 32
                    iconSize: Theme.iconSizeSmall
                    iconColor: Theme.surfaceVariantText
                    backgroundColor: Theme.surfaceContainerHigh
                    tooltipText: I18n.trFor("quickCapture", "Settings")
                    onClicked: PopoutService.openSettingsWithTab("plugins")
                }
            }
        }
    }
}
