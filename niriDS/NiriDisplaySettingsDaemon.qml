import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root
    pluginId: "niriDS"
    pluginService: PluginService

    NiriDisplaySettingsModal {
        id: modal
        Component.onCompleted: NiriDS.modal = modal
        onShouldBeVisibleChanged: {
            if (!shouldBeVisible && NiriDS.modalVisible) {
                NiriDS.modalVisible = false;
            }
        }
    }

    IpcHandler {
        target: "niriDS"
        enabled: true

        function open(): string {
            NiriDS.setDisplays();
            modal.openCentered();
            NiriDS.modalVisible = true;
            return "SUCCESS";
        }

        function close(): string {
            modal.close();
            NiriDS.modalVisible = false;
            return "SUCCESS";
        }

        function toggle(): string {
            if (NiriDS.modalVisible) {
                modal.close();
                NiriDS.modalVisible = false;
            } else {
                NiriDS.setDisplays();
                modal.openCentered();
                NiriDS.modalVisible = true;
            }
            return "SUCCESS";
        }

        function apply(profile: string): string {
            const needsExternal = ["external_only", "extend", "mirror"].includes(profile);
            if (needsExternal && !NiriDS.hasExternal) {
                return "ERROR: no external display connected";
            }
            NiriDS.apply(profile);
            return "SUCCESS";
        }

        function fallback(): string {
            NiriDS.enableInternalDisplay();
            return "SUCCESS";
        }
    }

    property int lastOutputCount: 0
    property int initTicks: 0
    property var cachedRawOutputs: ({})

    /**
     * Try to re‑enable the internal display in a way that is resilient to compositor timing.
     * Performs an immediate attempt plus deferred attempts to cover race conditions.
     */
    function enableInternalDisplayWithFallback() {
        NiriDS.enableInternalDisplay();
        Qt.callLater(() => NiriDS.enableInternalDisplay());
        Qt.callLater(() => Qt.callLater(() => NiriDS.enableInternalDisplay()));
    }

    function checkFallback() {
        const enableFallback = PluginService.loadPluginData("niriDS", "enableFallback", true);
        if (!enableFallback) return;

        // Kill wl-mirror first — its target output just disappeared
        NiriDS.stopMirror();

        root.enableInternalDisplayWithFallback();
    }

    function handleOutputsUpdated() {
        if (!NiriService.outputs) return;
        const prevTotalOutputs = Object.keys(cachedRawOutputs || {}).length;
        NiriDS.updateOutputs(NiriService.outputs);

        const current = NiriDS.displays.length;
        const totalOutputs = Object.keys(NiriDS.rawOutputs || {}).length;
        cachedRawOutputs = NiriDS.rawOutputs;

        // Skip initial updates to allow compositor state to settle
        if (initTicks < 2) {
            initTicks++;
            lastOutputCount = current;
            return;
        }

        if (totalOutputs > prevTotalOutputs) {
            const action = (pluginData && typeof pluginData.connectionAction === 'string' && pluginData.connectionAction)
                ? pluginData.connectionAction
                : "show_menu";

            if (action === "show_menu") {
                modal.openCentered();
                NiriDS.modalVisible = true;
            } else if (action !== "none") {
                NiriDS.apply(action);
            }
        } else if (lastOutputCount > 0 && current < lastOutputCount) {
            // Display count decreased - external monitor unplugged
            checkFallback();
        }

        lastOutputCount = current;
    }

    Connections {
        target: NiriService
        function onOutputsChanged() {
            root.handleOutputsUpdated();
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => root.handleOutputsUpdated());
    }
}
