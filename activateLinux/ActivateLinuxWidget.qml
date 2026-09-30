import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    minWidth: 400
    minHeight: 60

    readonly property bool customizeText: pluginData.customizeText ?? false
    readonly property string firstLine: customizeText
        ? (pluginData.firstLine || I18n.trFor("activateLinux", "Activate Linux"))
        : I18n.trFor("activateLinux", "Activate Linux")

    readonly property string secondLine: customizeText
        ? (pluginData.secondLine || I18n.trFor("activateLinux", "Go to Settings to activate Linux."))
        : I18n.trFor("activateLinux", "Go to Settings to activate Linux.")

    readonly property real watermarkOpacity: (pluginData.watermarkOpacity ?? 40) / 100.0
    readonly property int firstLineSize: pluginData.firstLineSize ?? Theme.fontSizeXLarge
    readonly property int secondLineSize: pluginData.secondLineSize ?? Theme.fontSizeMedium

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Theme.spacingXL * 2
            anchors.bottomMargin: Theme.spacingXL * 2

            ColumnLayout {
                spacing: Theme.spacingXXS

                StyledText {
                    text: firstLine
                    color: Theme.surfaceVariantText
                    font.pixelSize: firstLineSize
                    font.weight: Font.Light
                    opacity: watermarkOpacity
                }

                StyledText {
                    text: secondLine
                    color: Theme.surfaceVariantText
                    font.pixelSize: secondLineSize
                    opacity: watermarkOpacity
                }
            }
        }
    }
}