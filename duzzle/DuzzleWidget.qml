pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modules.Plugins
import "ui"
import "engine/SeedRandom.js" as SeedRandom
import "engine/DailyStats.js" as DailyStats

PluginComponent {
    id: root

    readonly property string todayStr: SeedRandom.getDailySeedString()
    property var cachedStats: ({})
    readonly property bool dailyDone: cachedStats && cachedStats.lastCompletedDate === todayStr

    function refreshStats() {
        if (root.pluginService) {
            cachedStats = DailyStats.loadStats(root.pluginService, root.pluginId);
        }
    }

    Component.onCompleted: {
        refreshStats();
    }

    ccWidgetIcon: "extension"
    ccWidgetPrimaryText: I18n.trFor("duzzle", "Duzzle")
    ccWidgetSecondaryText: {
        if (root.dailyDone) {
            var s = root.cachedStats ? (root.cachedStats.streak || 0) : 0;
            return I18n.trFor("duzzle", "Daily Done (%1 streak)").arg(s);
        }
        return I18n.trFor("duzzle", "Daily Puzzle");
    }
    ccWidgetIsActive: duzzleWindow.visible

    onCcWidgetToggled: {
        duzzleWindow.toggle();
        refreshStats();
    }

    DuzzleWindow {
        id: duzzleWindow
        pluginService: root.pluginService
        pluginId: root.pluginId
        onVisibleChanged: {
            if (!visible) {
                root.refreshStats();
            }
        }
    }
}
