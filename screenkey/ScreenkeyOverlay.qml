import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import "./shared"

PanelWindow {
    id: overlayWindow

    property var daemon: null
    readonly property string keycapStyle: daemon ? daemon.keycapStyle : "default"
    readonly property bool isCentered: daemon ? (daemon.position === "bottom_center" || daemon.position === "top_center") : false
    readonly property bool isMouseClick: daemon ? (daemon.displayText === "LMB Click" || daemon.displayText === "RMB Click" || daemon.displayText === "MMB Click") : false
    readonly property bool isOverlayVisible: daemon && (daemon.displayText !== "" || (daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive)))

    // Fullscreen transparent overlay surface to prevent any window resize jitter
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // Wayland specific window properties
    WlrLayershell.namespace: "dms:screenkey-overlay"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None // Absolutely critical: do not steal focus
    WlrLayershell.exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore

    mask: (daemon && daemon.clickThrough === false) ? interactiveMask : emptyMask

    Region {
        id: emptyMask
    }

    Region {
        id: interactiveMask
        item: cardContainer
    }

    // Dummy text to calculate a unified height based on current font size
    StyledText {
        id: dummyText
        visible: false
        font.pixelSize: daemon ? daemon.fontSize : 24
        font.bold: true
        text: "A"
    }

    readonly property real unifiedHeight: dummyText.implicitHeight + Theme.spacingXS * 2
    function resolveColor(val) {
        if (!val || val === "default" || val === "primary") return Theme.primary;
        if (typeof val === "string" && (val.startsWith("#") || val.startsWith("rgb"))) return Qt.color(val);
        return Theme.roleColor(val);
    }

    function getOverlayKeyText(keyText) {
        if (!daemon || !daemon.macSymbols) return keyText;
        const macMap = {
            "Ctrl": "⌃",
            "Alt": "⌥",
            "Shift": "⇧",
            "Super": "⌘",
            "Enter": "⏎",
            "Backspace": "⌫",
            "Tab": "⇥",
            "Esc": "⎋",
            "Space": "␣"
        };
        return macMap[keyText] || keyText;
    }

    readonly property color resolvedTextColor: daemon ? overlayWindow.resolveColor(daemon.textColor) : Theme.primary
    readonly property color resolvedKeycapTextColor: daemon ? overlayWindow.resolveColor(daemon.keycapTextColor) : Theme.primary
    readonly property bool roundedKeycaps: daemon ? daemon.roundedKeycaps : true
    readonly property color resolvedBgColor: {
        if (!daemon) return Theme.withAlpha(Theme.surface, 0.85);
        if (daemon.bgColor === "default" || !daemon.bgColor) return Theme.withAlpha(Theme.surface, 0.85);
        if (typeof daemon.bgColor === "string" && (daemon.bgColor.startsWith("#") || daemon.bgColor.startsWith("rgb"))) return Qt.color(daemon.bgColor);
        return Theme.roleColor(daemon.bgColor);
    }

    color: "transparent"

    StyledRect {
        id: cardContainer
        
        // Match contents with padding
        width: contentColumn.implicitWidth + Theme.spacingXL * 2
        height: contentColumn.implicitHeight + Theme.spacingL * 2
        
        readonly property real mSize: daemon ? daemon.marginSize : 24
        readonly property string pos: daemon ? daemon.position : "bottom_center"
        readonly property bool isTop: pos.startsWith("top")
        readonly property bool isLeft: pos.endsWith("left")
        readonly property bool isRight: pos.endsWith("right")
        readonly property bool isCentered: !isLeft && !isRight

        x: {
            if (isLeft) return mSize;
            if (isRight) return parent.width - width - mSize;
            return (parent.width - width) / 2;
        }

        y: {
            if (isTop) return mSize;
            return parent.height - height - mSize;
        }

        radius: Theme.cornerRadius
        color: overlayWindow.resolvedBgColor
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        state: (daemon && daemon.isExiting) ? "hidden" : (overlayWindow.isOverlayVisible ? "visible" : "hidden")
        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    target: cardContainer
                    opacity: 0.0
                    scale: (daemon && daemon.exitAnimation === "zoom") ? 0.9 : 1.0
                }
            },
            State {
                name: "visible"
                PropertyChanges {
                    target: cardContainer
                    opacity: daemon ? daemon.overlayOpacity / 100.0 : 0.9
                    scale: 1.0
                }
            }
        ]

        transitions: [
            // Entry transition (hidden -> visible)
            Transition {
                from: "hidden"
                to: "visible"

                ParallelAnimation {
                    // Opacity
                    NumberAnimation {
                        target: cardContainer
                        property: "opacity"
                        duration: (daemon && daemon.entryAnimation !== "none") ? M3E.spatialFastMs : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }

                    // Scale (Zoom)
                    NumberAnimation {
                        target: cardContainer
                        property: "scale"
                        from: (daemon && daemon.entryAnimation === "zoom") ? 0.9 : 1.0
                        to: 1.0
                        duration: (daemon && daemon.entryAnimation === "zoom") ? M3E.spatialFastMs : 0
                        easing.type: Easing.OutBack
                    }
                }
            },

            // Exit transition (visible -> hidden)
            Transition {
                from: "visible"
                to: "hidden"

                ParallelAnimation {
                    // Opacity
                    NumberAnimation {
                        target: cardContainer
                        property: "opacity"
                        duration: (daemon && daemon.exitAnimation !== "none") ? M3E.effectsMs : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }

                    // Scale (Zoom)
                    NumberAnimation {
                        target: cardContainer
                        property: "scale"
                        duration: (daemon && daemon.exitAnimation === "zoom") ? M3E.effectsMs : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }
            }
        ]

        Column {
            id: contentColumn
            x: Theme.spacingXL
            y: Theme.spacingL
            spacing: Theme.spacingS

            Repeater {
                model: daemon ? daemon.historyList : []
                delegate: Row {
                    id: historyRow
                    spacing: (daemon && daemon.macSymbols) ? Theme.spacingXS : Theme.spacingS
                    x: {
                        if (cardContainer.isRight) return contentColumn.width - width;
                        if (cardContainer.isLeft) return 0;
                        return (contentColumn.width - width) / 2;
                    }

                    readonly property string lineText: modelData.text
                    readonly property bool isCombo: modelData.isCombo
                    readonly property bool isMouseClick: lineText === "LMB Click" || lineText === "RMB Click" || lineText === "MMB Click"
                    readonly property var keysList: isCombo ? lineText.split(" + ") : []

                    // Render keycaps for combinations
                    Repeater {
                        model: isCombo ? keysList : 0
                        delegate: Row {
                            spacing: (daemon && daemon.macSymbols) ? Theme.spacingXS : Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter

                            // Ported keystrokes styles (Laptop, Low Profile, PBT, Minimal)
                            KeycapDelegate {
                                visible: overlayWindow.keycapStyle !== "default"
                                anchors.verticalCenter: parent.verticalCenter
                                label: modelData
                                skin: overlayWindow.keycapStyle
                                fontSize: daemon ? daemon.fontSize : 24
                                roundedCorners: overlayWindow.roundedKeycaps
                                customTextColor: overlayWindow.resolvedKeycapTextColor
                            }

                            // Original DMS default keycap style
                            StyledRect {
                                visible: overlayWindow.keycapStyle === "default"
                                anchors.verticalCenter: parent.verticalCenter
                                width: keycapText.implicitWidth + Theme.spacingM * 2
                                height: overlayWindow.unifiedHeight
                                radius: overlayWindow.roundedKeycaps ? Theme.cornerRadius / 2 : 0
                                color: Theme.surfaceContainerHighest
                                border.color: Theme.withAlpha(Theme.outline, 0.25)
                                border.width: 1

                                StyledText {
                                    id: keycapText
                                    anchors.centerIn: parent
                                    font.pixelSize: daemon ? daemon.fontSize : 24
                                    font.bold: true
                                    color: overlayWindow.resolvedKeycapTextColor
                                    text: overlayWindow.getOverlayKeyText(modelData)
                                }
                            }

                            // Render separator unless it is the last item
                            StyledText {
                                visible: index < keysList.length - 1
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: daemon ? daemon.fontSize : 24
                                font.bold: true
                                color: Theme.outline
                                text: daemon ? daemon.customSeparator : "+"
                            }
                        }
                    }

                    // Render mouse click indicator
                    Row {
                        id: mouseIcon
                        visible: isMouseClick
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS
                        height: overlayWindow.unifiedHeight

                        readonly property bool isLeft: lineText === "LMB Click"
                        readonly property bool isRight: lineText === "RMB Click"
                        readonly property bool isMiddle: lineText === "MMB Click"

                        Rectangle {
                            width: 14
                            height: 22
                            radius: 7
                            color: "transparent"
                            border.color: Theme.outline
                            border.width: 1.5
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 7
                                height: 11
                                radius: 3
                                color: mouseIcon.isLeft ? Theme.primary : "transparent"
                                border.color: Theme.outline
                                border.width: 1
                                anchors.left: parent.left
                                anchors.top: parent.top
                            }

                            Rectangle {
                                width: 7
                                height: 11
                                radius: 3
                                color: mouseIcon.isRight ? Theme.primary : "transparent"
                                border.color: Theme.outline
                                border.width: 1
                                anchors.right: parent.right
                                anchors.top: parent.top
                            }

                            Rectangle {
                                width: 2
                                height: 5
                                radius: 1
                                color: mouseIcon.isMiddle ? Theme.primary : Theme.outline
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 3
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: daemon ? daemon.fontSize : 24
                            font.bold: true
                            color: overlayWindow.resolvedKeycapTextColor
                            text: mouseIcon.isLeft ? "L" : (mouseIcon.isRight ? "R" : "M")
                        }
                    }

                    // Render standard text for normal typing
                    StyledText {
                        visible: !isCombo && !isMouseClick
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: daemon ? daemon.fontSize : 24
                        font.bold: true
                        color: overlayWindow.resolvedTextColor
                        text: overlayWindow.getOverlayKeyText(lineText)
                        
                        height: overlayWindow.unifiedHeight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Divider between history and active modifiers
            Rectangle {
                id: modifierDivider
                height: 1
                color: Theme.outline
                opacity: 0.2
                width: contentColumn.width
                visible: daemon && daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive) && daemon.historyList.length > 0
            }

            // Real-time held modifiers status bar
            Row {
                id: modifierStatusRow
                visible: daemon && daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive)
                spacing: Theme.spacingS
                layoutDirection: cardContainer.isRight ? Qt.RightToLeft : Qt.LeftToRight
                x: {
                    if (cardContainer.isRight) return contentColumn.width - width;
                    if (cardContainer.isLeft) return 0;
                    return (contentColumn.width - width) / 2;
                }

                // Ctrl Pill
                StyledRect {
                    visible: daemon && daemon.ctrlActive
                    height: overlayWindow.unifiedHeight
                    width: ctrlText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: ctrlText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimaryContainer
                        text: overlayWindow.getOverlayKeyText("Ctrl")
                    }
                }

                // Alt Pill
                StyledRect {
                    visible: daemon && daemon.altActive
                    height: overlayWindow.unifiedHeight
                    width: altText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: altText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimaryContainer
                        text: overlayWindow.getOverlayKeyText("Alt")
                    }
                }

                // Shift Pill
                StyledRect {
                    visible: daemon && daemon.shiftActive
                    height: overlayWindow.unifiedHeight
                    width: shiftText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: shiftText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimaryContainer
                        text: overlayWindow.getOverlayKeyText("Shift")
                    }
                }

                // Super Pill
                StyledRect {
                    visible: daemon && daemon.superActive
                    height: overlayWindow.unifiedHeight
                    width: superText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: superText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimaryContainer
                        text: overlayWindow.getOverlayKeyText("Super")
                    }
                }
            }
        }
    }
}
