pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import "./shared"

PluginComponent {
    id: root

    pluginId: "typingSounds"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["typingSounds"]

    property var packOptions: []
    property var deviceOptions: []
    property bool _packInit: false
    property bool _devInit: false

    readonly property string currentPackLabel: {
        var cur = root.daemon ? root.daemon.selectedPackPath : "";
        for (var i = 0; i < root.packOptions.length; i++) {
            if (root.packOptions[i].value === cur)
                return root.packOptions[i].label;
        }
        return root._packInit && root.packOptions.length > 0 ? root.packOptions[0].label : I18n.tr("Default Pack");
    }

    readonly property string currentDeviceLabel: {
        var cur = root.daemon ? root.daemon.selectedDevicePath : "all";
        for (var i = 0; i < root.deviceOptions.length; i++) {
            if (root.deviceOptions[i].value === cur)
                return root.deviceOptions[i].label;
        }
        return I18n.tr("All Keyboards (Auto)");
    }

    readonly property string volumeIcon: {
        const vol = root.daemon ? root.daemon.volume : 100;
        if (!root.daemon || !root.daemon.soundEnabled || vol === 0) return "volume_off";
        if (vol < 50) return "volume_down";
        return "volume_up";
    }

    function scanSoundpacks() {
        const script = `
import os, json, sys
res = []
for p in sys.argv[1:]:
    if not os.path.exists(p): continue
    for d in os.listdir(p):
        dp = os.path.join(p, d)
        cfg = os.path.join(dp, 'config.json')
        if os.path.exists(cfg):
            try:
                with open(cfg) as f:
                    name = json.load(f).get('name', d)
                    res.append((name, dp))
            except:
                res.append((d, dp))
print(json.dumps(res))
`;
        const localPath = Paths.expandTilde("~/.config/DankMaterialShell/plugins/typingSounds/soundpacks");
        const userPath = Paths.expandTilde("~/.config/dms-typing-sounds/soundpacks");
        Proc.runCommand("typingSounds.scanPacks", ["python3", "-c", script, userPath, localPath], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                    if (root.daemon)
                        root.daemon.preSlicePack(data[i][1]);
                }
                root.packOptions = options;
                root._packInit = true;
            } catch(e) {}
        });
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
                if m:
                    name = m.group(1)
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
        Proc.runCommand("typingSounds.scanDevices", ["python3", "-c", script], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [{ label: I18n.tr("All Keyboards (Auto)"), value: "all" }];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.deviceOptions = options;
                root._devInit = true;
            } catch(e) {}
        });
    }

    Component.onCompleted: {
        scanSoundpacks();
        scanDevices();
    }

    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.tr("Typing Sounds")
    ccWidgetSecondaryText: daemon && daemon.soundEnabled ? I18n.tr("Enabled") : I18n.tr("Disabled")
    ccWidgetIsActive: daemon ? daemon.soundEnabled : false
    ccDetailHeight: {
        const hasWarning = !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup));
        return hasWarning ? 400 : 345;
    }

    onCcWidgetToggled: {
        if (daemon) {
            var newState = !daemon.soundEnabled;
            daemon.saveSetting("soundEnabled", newState);
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

                // ── Volume Card ──────────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: volumeCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.withAlpha(Theme.outline, 0.08)
                    border.width: 1

                    Column {
                        id: volumeCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: Math.max(volTitleRow.implicitHeight, volValueText.implicitHeight)

                            Row {
                                id: volTitleRow
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: root.volumeIcon
                                    size: Theme.iconSizeSmall
                                    color: (root.daemon?.soundEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: I18n.tr("Volume")
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StyledText {
                                id: volValueText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.daemon ? root.daemon.volume : 100) + "%"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.SemiBold
                                font.features: { "tnum": 1 }
                                color: (root.daemon?.soundEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                            }
                        }

                        DankSliderPlus {
                            width: parent.width
                            height: 32
                            value: root.daemon ? root.daemon.volume : 100
                            minimum: 0
                            maximum: 200
                            unit: "%"
                            showValue: false
                            wheelEnabled: true
                            onSliderValueChanged: (newValue) => {
                                if (root.daemon)
                                    root.daemon.saveSetting("volume", newValue);
                            }
                        }
                    }
                }

                // ── Sound & Device Selectors Card ───────────────────────────
                Rectangle {
                    width: parent.width
                    height: selectorCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.color: Theme.withAlpha(Theme.outline, 0.08)
                    border.width: 1

                    Column {
                        id: selectorCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        // Sound Pack Section
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS

                            Item {
                                width: parent.width
                                height: 20

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: "library_music"
                                        size: Theme.iconSizeSmall
                                        color: Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: I18n.tr("Sound Pack")
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.daemon?.isPreparing ? I18n.tr("Preparing…") : (root.packOptions.length > 0 ? I18n.tr("%1 packs").arg(root.packOptions.length) : "")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: root.daemon?.isPreparing ? Theme.warning : Theme.surfaceVariantText
                                }
                            }

                            DankDropdown {
                                width: parent.width
                                height: 38
                                compactMode: true
                                currentValue: root.currentPackLabel
                                options: root.packOptions.map(function(o) { return o.label; })
                                onValueChanged: (newValue) => {
                                    for (var i = 0; i < root.packOptions.length; i++) {
                                        if (root.packOptions[i].label === newValue) {
                                            if (root.daemon)
                                                root.daemon.saveSetting("selectedPackPath", root.packOptions[i].value);
                                            break;
                                        }
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.outline, 0.06)
                        }

                        // Keyboard Device Section
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "keyboard_alt"
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
                                currentValue: root.currentDeviceLabel
                                options: root.deviceOptions.map(function(o) { return o.label; })
                                onValueChanged: (newValue) => {
                                    for (var i = 0; i < root.deviceOptions.length; i++) {
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
                }

                // ── Mouse Interaction & Settings Card ───────────────────────
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
                            name: "mouse"
                            size: Theme.iconSizeSmall
                            color: (root.daemon?.mouseEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                        }

                        StyledText {
                            text: I18n.tr("Mouse Clicks")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankToggle {
                            id: mouseToggle
                            hideText: true
                            anchors.verticalCenter: parent.verticalCenter
                            checked: root.daemon ? root.daemon.mouseEnabled : false
                            onToggled: (checked) => {
                                if (root.daemon)
                                    root.daemon.saveSetting("mouseEnabled", checked);
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
