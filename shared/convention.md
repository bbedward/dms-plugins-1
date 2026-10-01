# DMS Plugin Development Conventions

This document outlines the standard patterns and structural requirements for Dank Material Shell plugins to ensure consistency across the ecosystem.

## 1. Directory Structure
- Plugin folders must be **camelCase** (e.g., `ambientSound`, `qrGenerator`).
- Repository names should be **kebab-case** with a `dms-` prefix (e.g., `dms-ambient-sound`).
- Local `components` directories are **deprecated**. Use `import "./shared"` for shared UI components.

## 2. Settings Layout (`PluginSettings.qml`)
To maintain a consistent user experience, the settings page should follow this order:

1.  **PluginHeader**: Title of the settings page.
2.  **Usage Guide**: A `SettingsCard` containing the `UsageGuide` component. This must be the **first** section after the header so users know how to use the plugin immediately.
3.  **General Settings**: Main functional toggles and configurations.
4.  **Appearance/Display**: UI-related settings (e.g., icon only mode, date formats).
5.  **Feedback/Notifications**: Sound, haptics, and toast settings.
6.  **Advanced**: Rarely used or complex configurations.

### Example:
```qml
PluginSettings {
    id: root
    pluginId: "myPlugin"

    PluginHeader { title: "My Plugin Settings" }

    // ALWAYS AT THE TOP
    SettingsCard {
        SectionTitle { text: "Usage Guide" }
        UsageGuide {
            items: [
                "Feature 1: How to use it.",
                "Shortcuts: Keyboard bindings."
            ]
        }
    }

    SettingsCard {
        SectionTitle { text: "General" }
        // ... settings ...
    }
}
```

## 3. Component Usage
- Use **`UsageGuide`** from `shared` instead of hardcoded bullet points in `InfoText`.
- Avoid `import qs.Services` unless explicitly required and tested.
- Standard imports:
  ```qml
  import QtQuick
  import QtQuick.Controls
  import qs.Common
  import qs.Widgets
  import qs.Modules.Plugins
  import "./shared"
  ```

## 4. Built-in Utilities & Dependency Minimization
Do not declare external package dependencies for capabilities that DMS provides natively:

### CLI Built-in Replacements
- **Clipboard**: Use `["dms", "cl", "copy", text]` / `["dms", "cl", "paste"]` instead of `wl-clipboard` (`wl-copy`/`wl-paste`), `xclip`.
- **Notifications**: Use `["dms", "notify", title, message]` instead of `libnotify` (`notify-send`).
- **Screenshots**: Use `["dms", "screenshot", "region"|"full"|"all"]` instead of `grim`, `slurp`, `grimblast`.
- **Downloads**: Use `["dms", "dl", url, "-o", path]` instead of `curl`/`wget` for basic file fetches.
- **Open File/URL**: Use `["dms", "open", target]` instead of `xdg-open`, `gio open`.
- **QR Codes**: Use `["dms", "qr", text]` instead of `qrencode`.
- **Trash**: Use `["dms", "trash", "put"|"list", path]` instead of `trash-cli`, `rm`.
- **Brightness**: Use `["dms", "brightness", percent]` instead of `brightnessctl`.
- **Display Query**: Use `["dms", "randr"]` instead of `wlr-randr`, `xrandr`.

### Native QML Services (Avoid Spawning Shells)
- **Audio Control**: Use `AudioService` (`defaultSink.volume`, `setVolume`, `toggleMute`) instead of `pactl`/`wpctl`.
- **Network / VPN**: Use `NetworkService` (`activeVpn`, `vpnConnections`, `toggleVpn`) instead of `nmcli`.
- **Bluetooth**: Use `BluetoothService` instead of `bluetoothctl`.
- **Session / DND**: Use `SessionData.setDoNotDisturb(...)` and `SessionService` instead of `systemctl`/`loginctl`.
- **Display / Outputs**: Bind to `NiriService.outputs` or `CompositorService.screens` instead of polling `niri msg outputs`.
- **State Storage**: Use `PluginService.loadPluginState()` / `savePluginState()` instead of `cat`/`printf` via `sh -c`.
- **Process Signals**: Use `processInstance.signal(signum)` instead of `killall` / `pkill` (`psmisc`).

