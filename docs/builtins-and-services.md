# Built-in Alternatives & Native Services

To keep plugins lightweight and minimize external dependencies, prefer DMS built-in CLI commands and in-process QML services over spawning external shell commands.

---

## 1. CLI Replacements (`dms <command>`)

Never require external packages when DMS provides built-in replacements:

| Capability | External Package to Avoid | DMS Built-in Command | Advantage |
| :--- | :--- | :--- | :--- |
| **Clipboard** | `wl-clipboard` (`wl-copy`, `wl-paste`), `xclip` | `dms cl copy <text>`, `dms cl paste` | Works uniformly across compositors |
| **Notifications** | `libnotify` (`notify-send`) | `dms notify "<title>" "<message>"` | Integrates with DMS notification center, supports `--file` |
| **Screenshots** | `grim`, `slurp`, `grimblast`, `flameshot` | `dms screenshot [region\|full\|all]` | Native Wayland capture with region selector |
| **Downloads** | `curl`, `wget` (for basic file/image fetch) | `dms dl <url> -o <path>` | Built-in downloader |
| **Open File / URL** | `xdg-open`, `gio open` | `dms open <url\|path>` | Uses DMS application picker |
| **QR Codes** | `qrencode` | `dms qr "<text>"` | Built-in encoder; supports terminal display or PNG stdout |
| **Trash** | `trash-cli`, `rm` | `dms trash [put\|list\|restore\|empty]` | Conforms to XDG Trash Spec 1.0 safely without shell rm |
| **Brightness** | `brightnessctl` | `dms brightness <percent>` | Direct hardware brightness control |
| **Display Query** | `wlr-randr`, `xrandr` | `dms randr` | Returns output metadata in structured JSON |

---

## 2. In-Process QML Services (Avoid Spawning Shells)

When writing QML, bind directly to native DMS services (`import qs.Services`) instead of spawning shell processes via `Proc.runCommand`:

| Capability | Shell Command to Avoid | QML API to Use |
| :--- | :--- | :--- |
| **Audio Volume & Mute** | `pactl`, `wpctl`, `amixer` | `AudioService` (`defaultSink.volume`, `defaultSink.muted`, `setVolume`, `toggleMute`) |
| **Network & VPN** | `nmcli`, `ip route` | `NetworkService` (`activeVpn`, `vpnConnections`, `toggleVpn`) |
| **Bluetooth** | `bluetoothctl` | `BluetoothService` (`devices`, `toggleDevice`, `adapterState`) |
| **Do Not Disturb & Power** | `loginctl`, `systemctl suspend` | `SessionData.setDoNotDisturb(...)`, `SessionService` |
| **Output / Display Events**| Polling `niri msg outputs` or `hyprctl` | `NiriService.outputs` or `CompositorService.screens` reactive bindings |
| **State Persistence** | `sh -c 'printf ... > file'` | `PluginService.loadPluginState()` / `savePluginState()` |
| **Process Control** | `killall -SIG...`, `pkill` (`psmisc`) | `Quickshell.Io.Process.signal(signum)` on the process instance |

---

## 3. Safe Command Execution

When external process execution is unavoidable:
- Pass arguments as arrays (`command: ["bin", "arg1", "arg2"]`) rather than shell string concatenation (`"bin " + userInput`).
- Never interpolate variables into `sh -c` strings. Pass parameters as positional arguments: `["sh", "-c", 'cmd "$1"', "sh", userInput]`.
