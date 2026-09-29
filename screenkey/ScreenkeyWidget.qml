pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    pluginId: "screenkey"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["screenkey"]
    property var deviceOptions: []
    property bool devicesScanning: true
    readonly property string autoDeviceLabel: I18n.tr("All Keyboards (Auto)")

    readonly property string currentDeviceLabel: {
        if (root.devicesScanning)
            return I18n.tr("Scanning devices…");
        const cur = root.daemon ? root.daemon.selectedDevicePath : "all";
        for (let i = 0; i < root.deviceOptions.length; i++) {
            if (root.deviceOptions[i].value === cur)
                return root.deviceOptions[i].label;
        }
        return root.autoDeviceLabel;
    }

    function scanDevices() {
        const script = `
import os, json, re
include_pattern = "kanata"
exclude_pattern = ["power button", "video bus", "speaker", "headphone", "lid switch", "touchpad", "extra buttons", "uinput", "server", "hitune", "inphic", "instant", "webcam", "video"]
devs = []
if os.path.exists('/proc/bus/input/devices'):
    with open('/proc/bus/input/devices', encoding='utf-8', errors='replace') as f:
        content = f.read()
    sections = content.strip().split('\\n\\n')
    for section in sections:
        name = ""
        handlers = ""
        for line in section.split('\\n'):
            if line.startswith('N: Name='):
                m = re.search(r'Name="([^"]+)"', line)
                if m: name = m.group(1)
            elif line.startswith('H: Handlers='):
                handlers = line.split('=')[1]
        if name and handlers:
            lower_name = name.lower()
            is_included = include_pattern in lower_name
            is_excluded = any(x in lower_name for x in exclude_pattern)
            if 'kbd' in handlers and (is_included or ('mouse' not in handlers and not is_excluded)):
                event_match = re.search(r'event(\\d+)', handlers)
                if event_match:
                    event_path = "/dev/input/event" + event_match.group(1)
                    devs.append((name + " (" + event_path.split('/')[-1] + ")", event_path))
print(json.dumps(devs))
`;
        const defaultOptions = [{ label: root.autoDeviceLabel, value: "all" }];
        root.devicesScanning = true;

        Proc.runCommand("screenkey.scanDevices", ["python3", "-c", script], (stdout, exitCode) => {
            if (exitCode !== 0) {
                console.warn("[Screenkey] scanDevices command failed with exit code:", exitCode, stdout);
                root.deviceOptions = defaultOptions;
                root.devicesScanning = false;
                return;
            }
            try {
                const data = JSON.parse(stdout.trim());
                var options = defaultOptions.slice();
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.deviceOptions = options;
            } catch(e) {
                console.warn("[Screenkey] Failed to parse scanDevices output:", e, stdout);
                root.deviceOptions = defaultOptions;
            } finally {
                root.devicesScanning = false;
            }
        });
    }

    Component.onCompleted: {
        scanDevices();
    }

    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.tr("Screenkey")
    ccWidgetSecondaryText: daemon && daemon.visualizerEnabled ? I18n.tr("Active") : I18n.tr("Disabled")
    ccWidgetIsActive: daemon ? daemon.visualizerEnabled : false
    ccDetailHeight: {
        const hasWarning = !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup));
        return hasWarning ? 420 : 360;
    }

    onCcWidgetToggled: {
        if (daemon) {
            daemon.saveSetting("visualizerEnabled", !daemon.visualizerEnabled);
        }
    }

    ccDetailContent: Component {
        Item {
            id: detailRoot
            implicitHeight: detailColumn.implicitHeight

            Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // ── Warning Banner ───────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: warningRow.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.warning, 0.12)
                    border.color: Theme.withAlpha(Theme.warning, 0.3)
                    border.width: 1
                    visible: !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup))

                    Row {
                        id: warningRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "warning"
                            size: Theme.iconSizeSmall
                            color: Theme.warning
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            width: parent.width - Theme.iconSizeSmall - Theme.spacingM
                            text: root.daemon?.notInInputGroup
                                ? I18n.tr("User not in 'input' group (run: sudo usermod -aG input $USER)")
                                : I18n.tr("Missing tool: %1").arg(root.daemon?.requiredTool ?? "libinput")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.warning
                            wrapMode: Text.WordWrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── Keyboard Device Card ─────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: deviceCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.withAlpha(Theme.outline, 0.08)
                    border.width: 1

                    Column {
                        id: deviceCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "keyboard"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Keyboard Device")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        DankDropdown {
                            width: parent.width
                            height: 38
                            compactMode: true
                            enabled: !root.devicesScanning
                            currentValue: root.currentDeviceLabel
                            options: root.deviceOptions.map(function(o) { return o.label; })
                            onValueChanged: (newValue) => {
                                for (let i = 0; i < root.deviceOptions.length; i++) {
                                    if (root.deviceOptions[i].label === newValue) {
                                        if (root.daemon)
                                            root.daemon.saveSetting("selectedDevicePath", root.deviceOptions[i].value);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Display Options Card ─────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: displayCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.withAlpha(Theme.outline, 0.08)
                    border.width: 1

                    Column {
                        id: displayCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "tune"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Display Options")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: Theme.spacingS
                            rowSpacing: Theme.spacingXS

                            DankToggle {
                                width: (parent.width - parent.spacing) / 2
                                text: I18n.tr("Shortcuts")
                                Binding on checked {
                                    value: root.daemon ? root.daemon.showShortcuts : true
                                }
                                onToggled: (checked) => {
                                    if (root.daemon)
                                        root.daemon.saveSetting("showShortcuts", checked);
                                }
                            }

                            DankToggle {
                                width: (parent.width - parent.spacing) / 2
                                text: I18n.tr("Normal Keys")
                                Binding on checked {
                                    value: root.daemon ? root.daemon.showNormalKeys : false
                                }
                                onToggled: (checked) => {
                                    if (root.daemon)
                                        root.daemon.saveSetting("showNormalKeys", checked);
                                }
                            }

                            DankToggle {
                                width: (parent.width - parent.spacing) / 2
                                text: I18n.tr("Mouse Clicks")
                                Binding on checked {
                                    value: root.daemon ? root.daemon.showMouseClicks : false
                                }
                                onToggled: (checked) => {
                                    if (root.daemon)
                                        root.daemon.saveSetting("showMouseClicks", checked);
                                }
                            }

                            DankToggle {
                                width: (parent.width - parent.spacing) / 2
                                text: I18n.tr("Held Modifiers")
                                Binding on checked {
                                    value: root.daemon ? root.daemon.showModifierStatus : false
                                }
                                onToggled: (checked) => {
                                    if (root.daemon)
                                        root.daemon.saveSetting("showModifierStatus", checked);
                                }
                            }

                            DankToggle {
                                width: (parent.width - parent.spacing) / 2
                                text: I18n.tr("macOS Symbols")
                                Binding on checked {
                                    value: root.daemon ? root.daemon.macSymbols : false
                                }
                                onToggled: (checked) => {
                                    if (root.daemon)
                                        root.daemon.saveSetting("macSymbols", checked);
                                }
                            }
                        }
                    }
                }

                // ── Visualizer Overlay & Settings Card ───────────────────────
                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.withAlpha(Theme.outline, 0.08)
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: (root.daemon?.visualizerEnabled ?? false) ? "visibility" : "visibility_off"
                            size: Theme.iconSizeSmall
                            color: (root.daemon?.visualizerEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                        }

                        StyledText {
                            text: I18n.tr("Visualizer Overlay")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankToggle {
                            id: visualizerToggle
                            hideText: true
                            anchors.verticalCenter: parent.verticalCenter
                            Binding on checked {
                                value: root.daemon ? root.daemon.visualizerEnabled : false
                            }
                            onToggled: (checked) => {
                                if (root.daemon)
                                    root.daemon.saveSetting("visualizerEnabled", checked);
                            }
                        }
                    }

                    DankActionButton {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "settings"
                        buttonSize: 32
                        iconSize: 18
                        iconColor: Theme.surfaceVariantText
                        tooltipText: I18n.tr("Settings")
                        tooltipSide: "bottom"
                        onClicked: {
                            PopoutService.closeControlCenter();
                            PopoutService.openSettingsWithTab("plugins");
                        }
                    }
                }
            }
        }
    }
}
