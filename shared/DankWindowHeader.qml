pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var controls
    property string title: ""
    property real titleFontSize: Theme.fontSizeMedium
    property int titleWeight: Font.DemiBold
    property int titleAlignment: Text.AlignHCenter
    property bool wrapTitle: false
    property real horizontalPadding: -1
    property real verticalPadding: Theme.spacingXS
    property bool showDivider: true
    property string subtitle: ""
    property string iconName: ""
    property bool closeEnabled: true
    property string closeTooltipText: ""
    default property alias actions: extraActions.data

    readonly property bool centered: titleAlignment === Text.AlignHCenter
    readonly property bool decorated: controls !== null
    readonly property real controlInset: (height - buttons.implicitHeight) / 2
    readonly property real edgeInset: horizontalPadding >= 0 ? horizontalPadding : controlInset
    readonly property real titleGap: horizontalPadding >= 0 ? horizontalPadding : Theme.spacingM
    readonly property real buttonsReserve: buttons.width + edgeInset + titleGap

    signal closeRequested

    implicitHeight: Math.max(decorated ? Theme.buttonHeightS : 0, Math.max(buttons.implicitHeight, titleColumn.implicitHeight) + verticalPadding * 2)
    height: implicitHeight
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    component WindowButton: DankActionButton {
        buttonSize: Theme.buttonHeightXXS
        iconSize: Theme.iconSizeSmall
        iconColor: Theme.surfaceText
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: buttons.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.spacingM
        enabled: root.controls !== null
        onPressed: {
            if (root.controls && typeof root.controls.tryStartMove === "function") {
                root.controls.tryStartMove();
            }
        }
        onDoubleClicked: {
            if (root.controls && typeof root.controls.tryToggleMaximize === "function") {
                root.controls.tryToggleMaximize();
            }
        }
    }

    Column {
        id: titleColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Math.max(0, root.width - (buttons.width + root.edgeInset) * 2))
        spacing: Theme.spacingXXS

        Text {
            id: titleText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            font.pixelSize: root.titleFontSize
            font.weight: root.titleWeight
            color: Theme.surfaceText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            id: subtitleText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text !== ""
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: root.edgeInset
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS

        Row {
            id: extraActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS
        }

        WindowButton {
            objectName: "minimizeWindow"
            visible: root.controls && root.controls.canMinimize ? true : false
            iconName: "minimize"
            Accessible.name: I18n.tr("Minimize")
            onClicked: {
                if (root.controls && typeof root.controls.tryMinimize === "function") {
                    root.controls.tryMinimize();
                }
            }
        }

        WindowButton {
            objectName: "maximizeWindow"
            visible: root.controls && root.controls.canMaximize ? true : false
            iconName: root.controls && root.controls.targetWindow && root.controls.targetWindow.maximized ? "fullscreen_exit" : "fullscreen"
            Accessible.name: root.controls && root.controls.targetWindow && root.controls.targetWindow.maximized ? I18n.tr("Restore") : I18n.tr("Maximize")
            onClicked: {
                if (root.controls && typeof root.controls.tryToggleMaximize === "function") {
                    root.controls.tryToggleMaximize();
                }
            }
        }

        WindowButton {
            objectName: "closeWindow"
            enabled: root.closeEnabled
            iconName: "close"
            tooltipText: root.closeTooltipText || null
            Accessible.name: root.closeTooltipText || I18n.tr("Close")
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.showDivider
        height: Theme.layerOutlineWidth
        color: Theme.outlineMedium
    }
}
