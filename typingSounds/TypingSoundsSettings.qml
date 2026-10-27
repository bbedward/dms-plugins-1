import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root

    pluginId: "typingSounds"

    readonly property string pluginDir: {
        if (root.pluginService && typeof root.pluginService.getPluginPath === "function") {
            const p = root.pluginService.getPluginPath(root.pluginId);
            if (p)
                return p;
        }
        return Paths.strip(Paths.config) + "/plugins/" + root.pluginId;
    }

    // Soundpack discovery lists
    property var packOptions: []
    // Keyboard devices
    property var deviceOptions: [{ label: "All Keyboards (Auto)", value: "all" }]

    Component.onCompleted: {
        scanSoundpacks();
        scanDevices();
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
        const localPath = root.pluginDir + "/soundpacks";
        const userPath = Paths.expandTilde("~/.config/dms-typing-sounds/soundpacks");

        Proc.runCommand("typingSounds.scanSoundpacks", ["python3", "-c", script, userPath, localPath], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.packOptions = options;
            } catch(e) {
                console.warn("[TypingSounds] Failed to parse pack scanner output:", e);
            }
        });
    }

    function scanDevices() {
        InputDeviceScanner.scanKeyboards("typingSounds.scanDevices", (devices) => {
            const options = [{ label: "All Keyboards (Auto)", value: "all" }];
            for (let i = 0; i < devices.length; i++) {
                options.push(devices[i]);
            }
            root.deviceOptions = options;
        });
    }

    SettingsCard {
        id: generalSection
        SectionTitle {
            text: I18n.tr("General")
            icon: "tune"
            showReset: enabledSetting.isDirty || volumeSetting.isDirty || mouseEnabledSetting.isDirty
            onResetClicked: {
                enabledSetting.resetToDefault();
                volumeSetting.resetToDefault();
                mouseEnabledSetting.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enabledSetting
            settingKey: "soundEnabled"
            label: I18n.tr("Enable Typing Sounds")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: volumeSetting
            settingKey: "volume"
            label: I18n.tr("Sound Volume")
            defaultValue: 100
            minimum: 0
            maximum: 200
            unit: "%"
            leftLabel: "0%"
            rightLabel: "200%"
        }

        Separator {}

        ToggleSettingPlus {
            id: mouseEnabledSetting
            settingKey: "mouseEnabled"
            label: I18n.tr("Mouse Interaction")
            description: I18n.tr("Play sounds for mouse clicks")
            defaultValue: false
        }
    }

    SettingsCard {
        id: deviceSection
        SectionTitle {
            text: I18n.tr("Device & Sounds")
            icon: "keyboard"
            showReset: selectedPackPathSetting.isDirty || selectedDevicePathSetting.isDirty
            onResetClicked: {
                selectedPackPathSetting.resetToDefault();
                selectedDevicePathSetting.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: selectedPackPathSetting
            settingKey: "selectedPackPath"
            label: I18n.tr("Sound Pack")
            options: root.packOptions
            defaultValue: ""
        }

        Separator {}

        SelectionSettingPlus {
            id: selectedDevicePathSetting
            settingKey: "selectedDevicePath"
            label: I18n.tr("Keyboard Device")
            options: root.deviceOptions
            defaultValue: "all"
        }
    }

    SettingsCard {
        id: ipcSection
        SectionTitle {
            id: ipcTitle
            text: I18n.tr("IPC Commands")
            icon: "terminal"
            collapsible: true
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: ipcTitle.isExpanded

            Repeater {
                model: [
                    { text: "dms ipc typingSounds toggle", label: I18n.tr("Toggle typing sounds") },
                    { text: "dms ipc typingSounds enable", label: I18n.tr("Enable typing sounds") },
                    { text: "dms ipc typingSounds disable", label: I18n.tr("Disable typing sounds") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.text
                }
            }
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("Play mechanical keyboard sounds globally as you type."),
                I18n.tr("You must be in the <b>input</b> group to allow keyboard event reading without root."),
                I18n.tr("Select a custom sound pack in the settings to change key sounds.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: creditsTitle
            text: I18n.tr("Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }

        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
                {
                    author: "Mechvibes",
                    url: "https://github.com/hainguyents13/mechvibes",
                    role: I18n.tr("Bundled mechanical keyboard sound packs."),
                    icon: "keyboard"
                }
            ]
        }
    }
}

