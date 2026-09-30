import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./shared"


PluginComponent {
    id: root
    readonly property bool showHints: pluginData.showHints ?? true


    // Right-click action on pill
    pillRightClickAction: () => root.toggleMute()

    // Layout constants
    readonly property real cellWidth: Math.floor((root.popoutWidth - (Theme.spacingL * 2) - (root.gridSpacing * 3)) / 4)
    readonly property real cellHeight: Theme.listItemTwoLineHeight + Theme.spacingS
    readonly property real iconSize: Theme.iconSize
    readonly property real fontSize: Theme.fontSizeSmall
    readonly property real gridSpacing: Theme.spacingS

    // Plugin directory (for sound files)
    readonly property string pluginDir: {
        var url = Qt.resolvedUrl(".").toString();
        if (url.startsWith("file://")) url = url.replace("file://", "");
        return url.endsWith("/") ? url.substring(0, url.length - 1) : url;
    }

    function hashString(value) {
        return Qt.md5(String(value));
    }

    function soundId(sound) {
        return sound.id || sound.name;
    }

    function getIpcSocket(soundId) {
        var safeId = String(soundId).replace(/[^A-Za-z0-9_.-]/g, "_").substring(0, 24);
        return "/tmp/dms-ambient-" + safeId + "-" + hashString(soundId) + ".sock";
    }

    function getSound(soundId) {
        for (var i = 0; i < sounds.length; i++) {
            if (root.soundId(sounds[i]) === soundId || sounds[i].name === soundId) return sounds[i];
        }
        return null;
    }

    function commandId(prefix, sound) {
        return prefix + "-" + hashString(sound);
    }

    // Sound definitions
    readonly property var bundledSounds: [
        { name: "rain", icon: "water_drop" },
        { name: "storm", icon: "thunderstorm" },
        { name: "wind", icon: "air" },
        { name: "waves", icon: "waves" },
        { name: "stream", icon: "water" },
        { name: "birds", icon: "flutter_dash" },
        { name: "forest", icon: "forest" },
        { name: "summer-night", icon: "dark_mode" },
        { name: "fireplace", icon: "local_fire_department" },
        { name: "coffee-shop", icon: "local_cafe" },
        { name: "city", icon: "location_city" },
        { name: "train", icon: "train" },
        { name: "boat", icon: "sailing" },
        { name: "acoustic-guitar", icon: "music_note" },
        { name: "warm-piano", icon: "piano" },
        { name: "ambient-music", icon: "library_music" },
        { name: "lofi-beats", icon: "headphones" },
        { name: "fan", icon: "mode_fan" },
        { name: "airplane", icon: "flight" },
        { name: "laundry-room", icon: "local_laundry_service" },
        { name: "white-noise", icon: "blur_on" },
        { name: "pink-noise", icon: "blur_linear" },
        { name: "brown-noise", icon: "blur_circular" },
        { name: "green-noise", icon: "lens_blur" }
    ]

    readonly property var customSounds: (pluginData.customSounds || []).map(sound => ({
        id: "custom:" + sound.path,
        name: sound.name,
        icon: "audiotrack",
        path: sound.path,
        custom: true
    }))
    readonly property var sounds: bundledSounds.concat(customSounds)
    readonly property var visibleSounds: sounds.filter(s => s.custom || (pluginData.hiddenSounds || []).indexOf(s.name) < 0)

    // Sleep timer presets
    readonly property var sleepPresets: [
        { label: "15m",  minutes: 15 },
        { label: "30m",  minutes: 30 },
        { label: "45m",  minutes: 45 },
        { label: "1h",   minutes: 60 },
        { label: "1.5h", minutes: 90 },
        { label: "2h",   minutes: 120 }
    ]

    // When Done options
    readonly property var whenDoneAudioOptions: [
        { label: I18n.tr("Stop"), icon: "stop", value: "stopAll" },
        { label: I18n.tr("Mute"), icon: "volume_off", value: "mute" }
    ]
    readonly property var whenDoneSystemOptions: [
        { label: I18n.tr("Lock"), icon: "lock", value: "lock" },
        { label: I18n.tr("Suspend"), icon: "bedtime", value: "suspend" },
        { label: I18n.tr("Power"), icon: "power_settings_new", value: "powerOff" }
    ]
    readonly property var whenDoneOptions: whenDoneAudioOptions.concat(whenDoneSystemOptions)
    property var whenDoneActions: pluginData.whenDoneActions || ["stopAll"]
    property bool timerSectionExpanded: false

    function isWhenDoneSelected(value) {
        return whenDoneActions.indexOf(value) >= 0;
    }

    function toggleWhenDoneAction(value) {
        var idx = whenDoneActions.indexOf(value);
        var newActions = whenDoneActions.slice();

        if (value === "stopAll" || value === "mute") {
            newActions = newActions.filter(a => a !== "stopAll" && a !== "mute");
            if (idx < 0) newActions.push(value);
        } else if (value === "lock" || value === "suspend" || value === "powerOff") {
            newActions = newActions.filter(a => a !== "lock" && a !== "suspend" && a !== "powerOff");
            if (idx < 0) newActions.push(value);
        } else {
            if (idx >= 0) {
                if (whenDoneActions.length > 1) {
                    newActions.splice(idx, 1);
                }
            } else {
                newActions.push(value);
            }
        }

        whenDoneActions = newActions;
        pluginService.savePluginData(root.pluginId, "whenDoneActions", newActions);
    }

    // Audio state
    property var playingSounds: []
    // Sessions retain their resolved paths even if a custom sound is removed from settings.
    property var activeSessions: ({})
    property var stopCallbacks: []
    property string playerBackend: ""
    property bool playerProbeComplete: false
    property var soundVolumes: pluginData.soundVolumes || ({})
    property int masterVolume: pluginData.defaultVolume !== undefined ? parseInt(pluginData.defaultVolume) : 100
    property bool isMuted: false

    function getEffectiveVolume(sound) {
        var individual = soundVolumes[sound] !== undefined ? soundVolumes[sound] : 100;
        return (individual / 100) * (root.isMuted ? 0 : root.masterVolume);
    }

    function setSoundVolume(sound, vol) {
        var volumes = Object.assign({}, soundVolumes);
        volumes[sound] = vol;
        soundVolumes = volumes;
        pluginService.savePluginData(root.pluginId, "soundVolumes", soundVolumes);
        var session = activeSessions[sound];
        if (session) session.applyVolume(getEffectiveVolume(sound));
    }

    // Preset state
    property var presets: pluginData.presets || []
    property int editingIndex: -1

    function savePreset() {
        if (playingSounds.length === 0) {
            ToastService.showError("Play some sounds first to save as preset!");
            return;
        }
        var newPresets = presets.slice();
        var presetName = "Preset " + (newPresets.length + 1);
        newPresets.push({
            name: presetName,
            sounds: playingSounds.slice(),
            volume: root.masterVolume
        });
        pluginService.savePluginData(root.pluginId, "presets", newPresets);
        ToastService.showInfo("Saved " + presetName);
    }

    function loadPreset(preset) {
        stopAll(() => {
            root.isMuted = false;
            root.masterVolume = preset.volume;
            var startedSounds = [];
            for (var i = 0; i < preset.sounds.length; i++) {
                if (root.startSound(preset.sounds[i])) startedSounds.push(preset.sounds[i]);
            }
            root.playingSounds = startedSounds;
        });
    }

    function togglePresetByName(presetName) {
        var foundPreset = null;
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].name === presetName) {
                foundPreset = presets[i];
                break;
            }
        }
        if (!foundPreset) return;

        var active = true;
        if (root.playingSounds.length !== foundPreset.sounds.length) {
            active = false;
        } else {
            for (var j = 0; j < foundPreset.sounds.length; j++) {
                if (root.playingSounds.indexOf(foundPreset.sounds[j]) < 0) {
                    active = false;
                    break;
                }
            }
        }

        if (active) {
            root.stopAll();
        } else {
            root.loadPreset(foundPreset);
        }
    }

    function deletePreset(index) {
        var newPresets = presets.slice();
        newPresets.splice(index, 1);
        pluginService.savePluginData(root.pluginId, "presets", newPresets);
    }

    function renamePreset(index, newName) {
        if (newName && newName.trim() !== "") {
            var newPresets = presets.slice();
            newPresets[index].name = newName.trim();
            pluginService.savePluginData(root.pluginId, "presets", newPresets);
            ToastService.showInfo("Preset renamed to " + newName);
        }
        editingIndex = -1;
    }

    function soundPath(soundData) {
        return soundData.path || (pluginDir + "/sounds/" + soundData.name + ".ogg");
    }

    function startSound(sound) {
        if (!playerProbeComplete) {
            ToastService.showWarning("Audio player check is still running.");
            return false;
        }
        if (!playerBackend) {
            ToastService.showError("Install mpv or ffplay for playback.");
            return false;
        }
        if (activeSessions[sound]) return true;

        var soundData = getSound(sound);
        if (!soundData) {
            ToastService.showWarning("A sound in this preset is no longer available.");
            return false;
        }

        var session = audioSessionComponent.createObject(root, {
            sessionId: sound,
            backend: playerBackend,
            sourcePath: soundPath(soundData),
            socketPath: getIpcSocket(sound),
            effectiveVolume: getEffectiveVolume(sound)
        });
        if (!session) return false;

        activeSessions[sound] = session;
        session.start();
        return true;
    }

    function stopSound(sound) {
        var session = activeSessions[sound];
        if (session) session.stop();
    }

    function sendIpcVolume(sound, socket, volume) {
        var command = JSON.stringify({ "command": ["set_property", "volume", volume] });
        Proc.runCommand(commandId("ipc", sound), [
            "sh", "-c",
            "printf '%s\\n' \"$1\" | socat - \"UNIX-CONNECT:$2\"",
            "sh", command, socket
        ], null, 0);
    }

    function handleSessionFinished(sound, session, exitCode) {
        if (activeSessions[sound] !== session) return;

        delete activeSessions[sound];
        Proc.runCommand(commandId("cleanup", sound), ["rm", "-f", session.socketPath], null, 0);

        var idx = playingSounds.indexOf(sound);
        if (idx >= 0) {
            var list = playingSounds.slice();
            list.splice(idx, 1);
            playingSounds = list;
        }

        if (!session.stopping && exitCode !== 0) {
            ToastService.showError("Failed to play " + (getSound(sound)?.name || "sound") + ".");
        }
        Qt.callLater(() => session.destroy());
        finishStopCallbacks();
    }

    function finishStopCallbacks() {
        if (Object.keys(activeSessions).length > 0 || stopCallbacks.length === 0) return;
        var callbacks = stopCallbacks.slice();
        stopCallbacks = [];
        for (var i = 0; i < callbacks.length; i++) callbacks[i]();
    }

    function updateAllVolumes() {
        for (var i = 0; i < playingSounds.length; i++) {
            var sound = playingSounds[i];
            var session = activeSessions[sound];
            if (session) session.applyVolume(getEffectiveVolume(sound));
        }
    }

    // Audio logic
    function toggleMute() {
        isMuted = !isMuted;
        updateAllVolumes();
    }
    
    function toggleSound(sound) {
        var idx = playingSounds.indexOf(sound);
        var list = playingSounds.slice();

        if (idx >= 0) {
            list.splice(idx, 1);
            playingSounds = list;
            stopSound(sound);
            if (list.length === 0) {
                root.isMuted = false;
            }
        } else {
            if (startSound(sound)) {
                list.push(sound);
                playingSounds = list;
            }
        }
    }

    function stopAll(callback) {
        playingSounds = [];
        isMuted = false;
        if (callback) stopCallbacks = stopCallbacks.concat([callback]);

        var sessionIds = Object.keys(activeSessions);
        for (var i = 0; i < sessionIds.length; i++) activeSessions[sessionIds[i]].stop();
        finishStopCallbacks();
    }

    function destroyAllSessions() {
        var sessionIds = Object.keys(activeSessions);
        for (var i = 0; i < sessionIds.length; i++) activeSessions[sessionIds[i]].destroy();
        activeSessions = {};
    }

    Process {
        id: playerProbe
        running: true
        command: ["sh", "-c", "if command -v mpv >/dev/null 2>&1; then printf mpv; elif command -v ffplay >/dev/null 2>&1; then printf ffplay; fi"]
        stdout: StdioCollector { id: playerProbeOutput }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.playerBackend = exitCode === 0 ? playerProbeOutput.text.trim() : "";
            root.playerProbeComplete = true;
        }
    }

    Component {
        id: audioSessionComponent
        AudioSession {
            id: audioSession
            onVolumeCommandRequested: (socketPath, volume) => root.sendIpcVolume(sessionId, socketPath, volume)
            onFinished: exitCode => root.handleSessionFinished(sessionId, audioSession, exitCode)
        }
    }

    function adjustVolume(delta) {
        var newVol = Math.min(100, Math.max(0, root.masterVolume + delta));
        if (newVol !== root.masterVolume) {
            root.masterVolume = newVol;
            updateAllVolumes();
        }
    }

    // Auto‑start key generator
    function autoStartKey(soundName) {
        return "autoStart" + soundName.charAt(0).toUpperCase() + soundName.slice(1).replace("-", "");
    }

    // Timers
    Timer {
        id: autoStartTimer
        interval: 2000
        onTriggered: {
            var mode = pluginData.autoStartMode || "preset";
            if (mode === "preset") {
                var presetName = pluginData.autoStartPreset || "";
                if (presetName !== "") {
                    root.togglePresetByName(presetName);
                }
            } else {
                for (var i = 0; i < root.sounds.length; i++) {
                    var key = autoStartKey(root.sounds[i].name);
                    if (pluginData[key]) root.toggleSound(root.sounds[i].name);
                }
            }
            if (pluginData.enableSleepTimer ?? true) {
                var minutes = parseInt(pluginData.defaultTimer ?? "30") || 30;
                if (minutes > 0) {
                    sleepTimer.interval = minutes * 60 * 1000;
                    sleepTimer.remainingTime = minutes * 60 * 1000;
                    sleepTimer.start();
                }
            }
        }
    }

    Timer {
        id: sleepTimer
        property int remainingTime: 0
        onTriggered: {
            executeWhenDone();
            remainingTime = 0;
        }
    }

    function executeWhenDone() {
        for (var i = 0; i < whenDoneActions.length; i++) {
            var action = whenDoneActions[i];
            if (action === "stopAll") {
                root.stopAll();
            } else if (action === "mute") {
                root.isMuted = true;
                root.updateAllVolumes();
            } else if (action === "lock") {
                Proc.runCommand("lock-screen", ["loginctl", "lock-session"], null, 0);
            } else if (action === "suspend") {
                Proc.runCommand("suspend", ["systemctl", "suspend"], null, 0);
            } else if (action === "powerOff") {
                Proc.runCommand("power-off", ["systemctl", "poweroff"], null, 0);
            }
        }
    }

    Timer {
        id: sleepCountdown
        interval: 1000
        repeat: true                     // tick every second
        running: sleepTimer.running
        onTriggered: sleepTimer.remainingTime = Math.max(0, sleepTimer.remainingTime - 1000);
    }

    Component.onCompleted: {
        autoStartTimer.start();
        // Initialize default preset only once
        if (pluginData.hasInitializedPresets === undefined) {
            var defaultPresets = [
                {
                    name: "Relaxing Rain",
                    sounds: ["rain", "birds", "wind"],
                    volume: 75
                }
            ];
            if (pluginService) {
                pluginService.savePluginData(root.pluginId, "presets", defaultPresets);
                pluginService.savePluginData(root.pluginId, "hasInitializedPresets", true);
            }
        }
    }

    Component.onDestruction: destroyAllSessions()

    // ── Pill (horizontal & vertical) ──
    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight

            // Mouse area for left click, middle click, and wheel
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        var preset = pluginData.middleClickAction || "";
                        if (preset !== "") {
                            root.togglePresetByName(preset);
                        }
                    } else {
                        root.triggerPopout();
                    }
                }
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y > 0 ? 10 : -10;
                    root.adjustVolume(delta);
                }
            }

            // Centered content row
            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: root.isMuted ? "volume_off" : (root.playingSounds.length > 0 ? "equalizer" : "music_note")
                    size: Theme.chipIconSize
                    color: root.isMuted ? Theme.error : (root.playingSounds.length > 0 ? Theme.primary : Theme.surfaceVariantText)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: horizontalBarPill

    // Popout dimensions
    popoutWidth: 440
    popoutHeight: {
        let gridRows = Math.ceil(root.visibleSounds.length / 4);
        let gridHeight = gridRows * root.cellHeight + (gridRows - 1) * root.gridSpacing;
        let baseH = 90; // Header + MediaHeader + spacing/padding
        if (root.timerSectionExpanded && (pluginData.showTimerSection ?? true)) baseH += 135; // Sleep presets & When Done card
        let h = baseH + gridHeight;
        if (root.presets.length > 0 || root.playingSounds.length > 0) {
            h += 40; // Save preset button / header row
            if (root.presets.length > 0) {
                let presetRows = Math.ceil(root.presets.length / 2);
                h += presetRows * Theme.buttonHeightXS + (presetRows - 1) * Theme.spacingXS + Theme.spacingS; // Presets flow height
            }
        }
        if (root.showHints && root.playingSounds.length > 0) h += 50;
        return Math.min(800, h);
    }

    component WhenDoneChip: Rectangle {
        id: chipRoot
        property string label: ""
        property string iconName: ""
        property string value: ""
        readonly property bool selected: root.isWhenDoneSelected(value)

        height: Theme.buttonHeightXS
        radius: Theme.cornerRadius
        color: selected
            ? Theme.withAlpha(Theme.primary, 0.18)
            : (chipMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
        border.width: 1
        border.color: selected ? Theme.primary : Theme.surfaceVariant

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXXS

            DankIcon {
                name: chipRoot.iconName
                size: Theme.iconSizeSmall
                color: chipRoot.selected ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: chipRoot.label
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: chipRoot.selected ? Font.DemiBold : Font.Normal
                color: chipRoot.selected ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: chipMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleWhenDoneAction(chipRoot.value)
        }
    }

    // Popout content
    popoutContent: Component {
        PopoutComponent {
            width: root.popoutWidth
            headerText: "Ambient Sound"
            detailsText: root.playingSounds.length > 0 ? root.playingSounds.length + " playing" : "Tap to play"
            showCloseButton: false

            headerActions: Component {
                Rectangle {
                    id: timerHeaderChip
                    visible: pluginData.showTimerSection ?? true
                    height: Theme.buttonHeightXXS
                    implicitWidth: timerChipRow.implicitWidth + Theme.spacingM
                    radius: height / 2
                    color: sleepTimer.running
                        ? Theme.primary
                        : (root.timerSectionExpanded ? Theme.withAlpha(Theme.primary, 0.15) : (timerMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh))
                    border.width: 1
                    border.color: sleepTimer.running
                        ? Theme.primary
                        : (root.timerSectionExpanded ? Theme.primary : Theme.surfaceVariant)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        id: timerChipRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "timer"
                            size: Theme.iconSizeSmall
                            color: sleepTimer.running
                                ? Theme.onPrimary
                                : (root.timerSectionExpanded ? Theme.primary : Theme.surfaceVariantText)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: sleepTimer.running
                                ? Math.ceil(sleepTimer.remainingTime / 60000) + "m"
                                : I18n.tr("Timer")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: sleepTimer.running ? Font.Bold : Font.Medium
                            color: sleepTimer.running
                                ? Theme.onPrimary
                                : (root.timerSectionExpanded ? Theme.primary : Theme.surfaceVariantText)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankIcon {
                            name: root.timerSectionExpanded ? "expand_less" : "expand_more"
                            size: 14
                            color: sleepTimer.running
                                ? Theme.onPrimary
                                : (root.timerSectionExpanded ? Theme.primary : Theme.surfaceVariantText)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: timerMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.timerSectionExpanded = !root.timerSectionExpanded
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                // Volume & Control bar
                MediaHeader {
                    volume: root.masterVolume / 100
                    isMuted: root.isMuted
                    showStopButton: true
                    stopButtonEnabled: root.playingSounds.length > 0
                    onVolumeChangeRequested: v => {
                        root.masterVolume = v * 100;
                        if (v > 0 && root.isMuted) root.isMuted = false;
                        root.updateAllVolumes();
                    }
                    onMuteToggled: root.toggleMute()
                    onStopClicked: root.stopAll()
                }

                // Timer & When Done Expandable Card
                Rectangle {
                    id: timerCard
                    width: parent.width
                    visible: root.timerSectionExpanded && (pluginData.showTimerSection ?? true)
                    height: visible ? timerCardContent.implicitHeight + (Theme.spacingS * 2) : 0
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerLow
                    border.width: 1
                    border.color: Theme.surfaceVariant
                    clip: true

                    Behavior on height { NumberAnimation { duration: 150 } }

                    Column {
                        id: timerCardContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS

                        // Duration presets or active countdown
                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS
                            visible: !sleepTimer.running

                            Repeater {
                                model: root.sleepPresets
                                delegate: DankButton {
                                    text: modelData.label
                                    width: (parent.width - (parent.spacing * (root.sleepPresets.length - 1))) / root.sleepPresets.length
                                    height: Theme.buttonHeightXS
                                    onClicked: {
                                        var ms = modelData.minutes * 60 * 1000;
                                        sleepTimer.interval = ms;
                                        sleepTimer.remainingTime = ms;
                                        sleepTimer.start();
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: sleepTimer.running

                            DankIcon {
                                name: "hourglass_top"
                                size: Theme.iconSizeMedium
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Sleep timer: ") + Math.ceil(sleepTimer.remainingTime / 60000) + I18n.tr(" minutes left")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 80 - parent.spacing * 2 - Theme.iconSizeMedium
                            }

                            DankButton {
                                text: I18n.tr("Cancel")
                                width: 80
                                height: Theme.buttonHeightXS
                                backgroundColor: Theme.surfaceContainerHighest
                                textColor: Theme.surfaceText
                                onClicked: sleepTimer.stop()
                            }
                        }

                        // When Done section
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("When done:")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceVariantText
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: root.whenDoneAudioOptions
                                    delegate: WhenDoneChip {
                                        width: Math.floor((parent.width - 1 - (parent.spacing * 5)) / 5)
                                        label: modelData.label
                                        iconName: modelData.icon
                                        value: modelData.value
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    height: 18
                                    color: Theme.surfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Repeater {
                                    model: root.whenDoneSystemOptions
                                    delegate: WhenDoneChip {
                                        width: Math.floor((parent.width - 1 - (parent.spacing * 5)) / 5)
                                        label: modelData.label
                                        iconName: modelData.icon
                                        value: modelData.value
                                    }
                                }
                            }
                        }
                    }
                }

                // Presets section - moved up for quick access
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.presets.length > 0 || root.playingSounds.length > 0

                    Item {
                        width: parent.width
                        height: Theme.buttonHeightXS

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Your Presets")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.surfaceVariantText
                            visible: root.presets.length > 0
                        }

                        DankButton {
                            id: saveButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Save Preset")
                            iconName: "bookmark_add"
                            buttonHeight: Theme.buttonHeightXXS
                            backgroundColor: "transparent"
                            textColor: Theme.primary
                            horizontalPadding: Theme.spacingM
                            visible: root.playingSounds.length > 0
                            onClicked: root.savePreset()
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: Theme.spacingXS
                        Repeater {
                            model: root.presets
                            delegate: Item {
                                width: (parent.width - Theme.spacingXS) / 2
                                height: Theme.buttonHeightXS

                                DankButton {
                                    id: presetButton
                                    text: modelData.name
                                    width: parent.width - 48
                                    height: parent.height
                                    visible: root.editingIndex !== index
                                    onClicked: root.loadPreset(modelData)
                                }

                                DankTextField {
                                    id: editField
                                    width: parent.width - 48
                                    height: parent.height
                                    text: modelData.name
                                    visible: root.editingIndex === index
                                    onEditingFinished: root.renamePreset(index, text)
                                    Component.onCompleted: {
                                        if (root.editingIndex === index) forceActiveFocus();
                                    }
                                }

                                DankIcon {
                                    name: root.editingIndex === index ? "check" : "edit"
                                    size: Theme.iconSizeSmall
                                    anchors.right: deleteIcon.left
                                    anchors.rightMargin: Theme.spacingXS
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.surfaceVariantText
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.editingIndex === index) {
                                                root.renamePreset(index, editField.text);
                                            } else {
                                                root.editingIndex = index;
                                            }
                                        }
                                    }
                                }

                                DankIcon {
                                    id: deleteIcon
                                    name: "close"
                                    size: Theme.iconSizeSmall
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.error
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.deletePreset(index)
                                    }
                                }
                            }
                        }
                    }
                }

                // Sound grid
                Flow {
                    width: parent.width
                    spacing: root.gridSpacing
                    
                    // Sound Tiles
                    Repeater {
                        model: root.visibleSounds
                        delegate: ActionTile {
                            readonly property string itemId: root.soundId(modelData)
                            width: root.cellWidth
                            height: root.cellHeight
                            iconName: modelData.icon
                            title: modelData.name.replace("-", " ")
                            titleFontSize: Theme.fontSizeSmall
                            subtitle: ""
                            volumeProgress: {
                                var vol = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                return vol / 100.0;
                            }
                            active: root.playingSounds.indexOf(itemId) >= 0
                            
                            onClicked: root.toggleSound(itemId)
                            onScrollUp: {
                                if (active) {
                                    var current = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                    root.setSoundVolume(itemId, Math.min(100, current + 5));
                                }
                            }
                            onScrollDown: {
                                if (active) {
                                    var current = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                    root.setSoundVolume(itemId, Math.max(0, current - 5));
                                }
                            }
                        }
                    }
                }

                // Footer (sleep timer + stop all)
                HintSection {
                    width: parent.width
                    showHints: root.showHints && root.playingSounds.length > 0

                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Middle-click bar icon to toggle your preset sound.")
                    }
                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Right-click bar icon to quickly mute/unmute.")
                    }
                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Scroll on a sound tile to adjust its individual volume.")
                    }
                }
            }
        }
    }
}
