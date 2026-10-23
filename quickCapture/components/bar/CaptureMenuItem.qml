import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../../shared"

Rectangle {
    id: root

    required property string icon
    required property string text
    property bool highlighted: false
    property bool showPin: true
    property string rightClickAction: "copy"
    property bool isFirst: false
    property bool isLast: false

    signal triggered(string action)

    readonly property bool canShowPin: showPin && rightClickAction !== "float"
    readonly property bool hovered: itemMouse.containsMouse || pinArea.containsMouse
    readonly property bool pressed: itemMouse.pressed || pinArea.pressed
    readonly property real hoverR: height / 2

    width: parent.width
    height: 40

    color: highlighted
        ? (hovered ? Theme.blend(Theme.primaryContainer, Theme.primary, M3E.activeBlendFactor) : Theme.primaryContainer)
        : (hovered ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

    topLeftRadius: pressed ? M3E.pressRadiusS : (hovered ? hoverR : (isFirst ? M3E.outerR : M3E.innerR))
    topRightRadius: pressed ? M3E.pressRadiusS : (hovered ? hoverR : (isFirst ? M3E.outerR : M3E.innerR))
    bottomLeftRadius: pressed ? M3E.pressRadiusS : (hovered ? hoverR : (isLast ? M3E.outerR : M3E.innerR))
    bottomRightRadius: pressed ? M3E.pressRadiusS : (hovered ? hoverR : (isLast ? M3E.outerR : M3E.innerR))

    scale: pressed ? M3E.rowPressScale : 1.0

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: M3E.spatialFastMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }
    Behavior on topRightRadius {
        NumberAnimation {
            duration: M3E.spatialFastMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: M3E.spatialFastMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }
    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: M3E.spatialFastMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: M3E.effectsMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveEffects
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: M3E.spatialFastMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: root.canShowPin ? 38 : Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS

        // M3E Morphing Icon Pill
        Rectangle {
            width: root.hovered || root.highlighted ? M3E.rowIconPillActiveWidth : M3E.rowIconPillWidth
            height: M3E.rowIconPillHeight
            radius: M3E.iconPillRadius(root.pressed, root.hovered, height)
            color: root.highlighted || root.hovered ? Theme.primary : Theme.surfaceContainerHighest
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation {
                    duration: M3E.spatialFastMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: M3E.curveFastSpatial
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: M3E.spatialFastMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: M3E.curveFastSpatial
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: M3E.effectsFastMs
                }
            }

            DIcon {
                anchors.centerIn: parent
                name: root.icon
                size: Theme.iconSizeSmall
                color: root.highlighted || root.hovered ? Theme.onPrimary : Theme.surfaceText
            }
        }

        StyledText {
            text: root.text
            font.pixelSize: Theme.fontSizeMedium
            font.weight: root.highlighted || root.hovered ? Font.Bold : Font.Medium
            color: root.highlighted
                ? Theme.onPrimaryContainer
                : (root.hovered ? Theme.onSecondaryContainer : Theme.surfaceText)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }

    DRipple {
        id: ripple
        anchors.fill: parent
        rippleColor: root.highlighted ? Theme.onPrimaryContainer : Theme.primary
        cornerRadius: root.topLeftRadius
        clip: true
    }

    // M3E Expressive Pin Pill
    Rectangle {
        id: pinPill
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: pinArea.pressed ? M3E.pressRadiusXS : height / 2
        color: pinArea.containsMouse ? Theme.tertiaryContainer : Theme.surfaceContainerHighest
        opacity: root.canShowPin && root.hovered ? 1 : 0
        scale: root.canShowPin && root.hovered ? (pinArea.containsMouse ? M3E.pinHoverScale : 1.0) : M3E.pinHiddenScale
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: M3E.effectsFastMs
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }

        DIcon {
            anchors.centerIn: parent
            name: "keep"
            size: 14
            color: pinArea.containsMouse ? Theme.onTertiaryContainer : Theme.surfaceVariantText
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        anchors.rightMargin: root.canShowPin ? 36 : 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => ripple.trigger(mouse.x, mouse.y)
        onClicked: mouse => root.triggered(mouse.button === Qt.RightButton ? root.rightClickAction : "edit")
    }

    MouseArea {
        id: pinArea
        visible: root.canShowPin
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 36
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => ripple.trigger(mouse.x + parent.width - width, mouse.y)
        onClicked: root.triggered("float")
    }
}
