import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Configuration
    property bool enabled: true
    property string selectedDevicePath: "all"
    property bool monitorMouse: false

    // Status properties
    property bool inputToolMissing: false
    property bool mouseToolMissing: false
    property bool notInInputGroup: false
    readonly property bool inputBroken: inputToolMissing || notInInputGroup
    readonly property string requiredTool: selectedDevicePath === "all" ? "libinput" : "evtest"

    // Unified Signals
    signal keyPressed(string keyName, int keyCode)
    signal keyReleased(string keyName, int keyCode)
    signal keyRepeated(string keyName, int keyCode)
    signal mousePressed(string buttonName, int buttonCode)
    signal rawLineReceived(string line)

    Component.onCompleted: {
        checkPermissionsAndTools();
    }

    onSelectedDevicePathChanged: {
        inputProc.running = false;
        inputRestartTimer.restart();
    }

    Timer {
        id: inputRestartTimer
        interval: 200
        onTriggered: {
            if (root.enabled && !root.inputToolMissing) {
                inputProc.running = true;
            }
        }
    }

    function checkPermissionsAndTools() {
        toolCheck.running = false;
        toolCheck.running = true;
        if (root.monitorMouse) {
            mouseToolCheck.running = false;
            mouseToolCheck.running = true;
        }
        groupCheck.running = false;
        groupCheck.running = true;
    }

    Process {
        id: toolCheck
        command: ["sh", "-c", "command -v " + root.requiredTool + " >/dev/null 2>&1"]
        running: false
        onExited: exitCode => {
            root.inputToolMissing = (exitCode !== 0);
        }
    }

    Process {
        id: mouseToolCheck
        command: ["sh", "-c", "command -v libinput >/dev/null 2>&1"]
        running: false
        onExited: exitCode => {
            root.mouseToolMissing = (exitCode !== 0);
        }
    }

    Process {
        id: groupCheck
        command: ["sh", "-c", "id -nG | tr ' ' '\\n' | grep -qx input"]
        running: false
        onExited: exitCode => {
            root.notInInputGroup = (exitCode !== 0);
        }
    }

    // Main keyboard (and auto-mode mouse) input process
    Process {
        id: inputProc
        command: {
            const cmd = root.selectedDevicePath === "all"
                ? ["libinput", "debug-events", "--show-keycodes"]
                : ["evtest", root.selectedDevicePath];
            return cmd;
        }
        running: root.enabled && !root.inputToolMissing

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.rawLineReceived(data);

                if (data.includes("EV_KEY")) {
                    const nameMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    const keyName = nameMatch ? nameMatch[1] : "";
                    const codeMatch = data.match(/code\s+(\d+)/);
                    const keyCode = codeMatch ? parseInt(codeMatch[1]) : 0;

                    // Mouse click events in evtest (e.g. BTN_LEFT 272)
                    if (keyCode >= 272 && keyCode <= 287) {
                        if (root.monitorMouse && data.includes("value 1")) {
                            let btnName = "Mouse Click";
                            if (keyCode === 272 || data.includes("BTN_LEFT")) btnName = "LMB Click";
                            else if (keyCode === 273 || data.includes("BTN_RIGHT")) btnName = "RMB Click";
                            else if (keyCode === 274 || data.includes("BTN_MIDDLE")) btnName = "MMB Click";
                            root.mousePressed(btnName, keyCode);
                        }
                        return;
                    }

                    if (data.includes("value 1")) {
                        root.keyPressed(keyName, keyCode);
                    } else if (data.includes("value 0")) {
                        root.keyReleased(keyName, keyCode);
                    } else if (data.includes("value 2")) {
                        root.keyRepeated(keyName, keyCode);
                    }
                } else if (data.includes("KEYBOARD_KEY")) {
                    const nameMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    const keyName = nameMatch ? nameMatch[1] : "";
                    const codeMatch = data.match(/\((\d+)\)/);
                    const keyCode = codeMatch ? parseInt(codeMatch[1]) : 0;

                    if (data.includes("pressed")) {
                        root.keyPressed(keyName, keyCode);
                    } else if (data.includes("released")) {
                        root.keyReleased(keyName, keyCode);
                    } else if (data.includes("repeat")) {
                        root.keyRepeated(keyName, keyCode);
                    }
                } else if (root.monitorMouse && data.includes("POINTER_BUTTON")) {
                    if (data.includes("pressed")) {
                        let btnName = "Mouse Click";
                        let btnCode = 0;
                        if (data.includes("BTN_LEFT") || data.includes("(272)")) {
                            btnName = "LMB Click";
                            btnCode = 272;
                        } else if (data.includes("BTN_RIGHT") || data.includes("(273)")) {
                            btnName = "RMB Click";
                            btnCode = 273;
                        } else if (data.includes("BTN_MIDDLE") || data.includes("(274)")) {
                            btnName = "MMB Click";
                            btnCode = 274;
                        }
                        root.mousePressed(btnName, btnCode);
                    }
                }
            }
        }

        stderr: StdioCollector {}
    }

    // Secondary mouse listener process for specific device mode (when evtest only monitors keyboard device)
    Process {
        id: mouseProc
        command: ["libinput", "debug-events"]
        running: root.enabled && root.monitorMouse && root.selectedDevicePath !== "all" && !root.mouseToolMissing

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("POINTER_BUTTON") && data.includes("pressed")) {
                    let btnName = "Mouse Click";
                    let btnCode = 0;
                    if (data.includes("BTN_LEFT") || data.includes("(272)")) {
                        btnName = "LMB Click";
                        btnCode = 272;
                    } else if (data.includes("BTN_RIGHT") || data.includes("(273)")) {
                        btnName = "RMB Click";
                        btnCode = 273;
                    } else if (data.includes("BTN_MIDDLE") || data.includes("(274)")) {
                        btnName = "MMB Click";
                        btnCode = 274;
                    }
                    root.mousePressed(btnName, btnCode);
                }
            }
        }

        stderr: StdioCollector {}
    }
}
