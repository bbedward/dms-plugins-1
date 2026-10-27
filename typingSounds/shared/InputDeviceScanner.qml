pragma Singleton
import QtQuick
import qs.Common

QtObject {
    id: root

    readonly property string pythonScanScript: `
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
`

    function scanKeyboards(jobId, callback) {
        Proc.runCommand(jobId, ["python3", "-c", pythonScanScript], (stdout, exitCode) => {
            if (exitCode !== 0) {
                console.warn("[InputDeviceScanner] Scan command failed with exit code:", exitCode, stdout);
                callback([]);
                return;
            }
            try {
                const data = JSON.parse(stdout.trim());
                const devices = [];
                for (let i = 0; i < data.length; i++) {
                    devices.push({ label: data[i][0], value: data[i][1] });
                }
                callback(devices);
            } catch(e) {
                console.warn("[InputDeviceScanner] Failed to parse devices JSON:", e, stdout);
                callback([]);
            }
        });
    }
}
