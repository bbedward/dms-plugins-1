import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../../shared"

Row {
    id: root

    property bool active: false
    property string iconOn: "mic"
    property string iconOff: "mic_off"
    property var options: []
    property string currentValue: ""

    signal toggled
    signal valueSelected(string value)

    readonly property string currentLabel: options.find(o => o.value === currentValue)?.label ?? currentValue

    width: parent.width
    spacing: Theme.spacingS

    Rectangle {
        id: toggleBox
        width: toggleArea.pressed ? 44 : 40
        height: 40
        radius: toggleArea.pressed
            ? M3E.pressRadiusXS
            : (root.active || toggleArea.containsMouse ? (Theme.cornerRadiusM ?? 12) : height / 2)
        color: root.active
            ? Theme.primary
            : (toggleArea.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHighest)

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
            name: root.active ? root.iconOn : root.iconOff
            size: Theme.iconSize - 2
            color: root.active
                ? Theme.onPrimary
                : (toggleArea.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
        }

        DRipple {
            id: ripple
            anchors.fill: parent
            rippleColor: root.active ? Theme.onPrimary : Theme.primary
            cornerRadius: toggleBox.radius
            clip: true
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => ripple.trigger(mouse.x, mouse.y)
            onClicked: root.toggled()
        }
    }

    DDropdown {
        width: parent.width - toggleBox.width - Theme.spacingS
        height: 40
        compactMode: true
        visible: root.active
        currentValue: root.currentLabel
        options: root.options.map(o => o.label)
        onValueChanged: {
            const match = root.options.find(o => o.label === value);
            if (match)
                root.valueSelected(match.value);
        }
    }
}
