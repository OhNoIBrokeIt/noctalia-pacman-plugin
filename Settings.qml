import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root
    spacing: Style.marginL

    property var pluginApi: null

    property int  editCheckIntervalMinutes: Math.max(
        1,
        Math.round(
            (pluginApi?.pluginSettings?.checkIntervalMs
             ?? pluginApi?.manifest?.metadata?.defaultSettings?.checkIntervalMs
             ?? 7200000) / 60000
        )
    )

    property int  editInitialAnimationSeconds: Math.max(
        1,
        Math.round(
            (pluginApi?.pluginSettings?.initialAnimationMs
             ?? pluginApi?.manifest?.metadata?.defaultSettings?.initialAnimationMs
             ?? 120000) / 1000
        )
    )

    property int  editIdleChompSeconds: Math.max(
        1,
        Math.round(
            (pluginApi?.pluginSettings?.idleChompMs
             ?? pluginApi?.manifest?.metadata?.defaultSettings?.idleChompMs
             ?? 30000) / 1000
        )
    )

    property bool editUseThemedIdleColor:
        pluginApi?.pluginSettings?.useThemedIdleColor
        ?? pluginApi?.manifest?.metadata?.defaultSettings?.useThemedIdleColor
        ?? true

    property bool editShowIdlePellet:
        pluginApi?.pluginSettings?.showIdlePellet
        ?? pluginApi?.manifest?.metadata?.defaultSettings?.showIdlePellet
        ?? true

    function saveSettings() {
        if (!pluginApi || !pluginApi.pluginSettings)
            return

        pluginApi.pluginSettings.checkIntervalMs = root.editCheckIntervalMinutes * 60000
        pluginApi.pluginSettings.initialAnimationMs = root.editInitialAnimationSeconds * 1000
        pluginApi.pluginSettings.idleChompMs = root.editIdleChompSeconds * 1000
        pluginApi.pluginSettings.useThemedIdleColor = root.editUseThemedIdleColor
        pluginApi.pluginSettings.showIdlePellet = root.editShowIdlePellet
        pluginApi.saveSettings()
    }

    NComboBox {
        label: "Check interval"
        description: "How often the widget checks for updates."
        model: [
            { "key": 5,   "name": "5 minutes" },
            { "key": 15,  "name": "15 minutes" },
            { "key": 30,  "name": "30 minutes" },
            { "key": 60,  "name": "1 hour" },
            { "key": 120, "name": "2 hours" },
            { "key": 240, "name": "4 hours" }
        ]
        currentKey: root.editCheckIntervalMinutes
        onSelected: key => root.editCheckIntervalMinutes = key
        defaultValue: Math.max(
            1,
            Math.round(
                (pluginApi?.manifest?.metadata?.defaultSettings?.checkIntervalMs ?? 7200000) / 60000
            )
        )
        minimumWidth: 200
    }

    NComboBox {
        label: "Initial animation duration"
        description: "How long Pac-Man animates after updates are detected."
        model: [
            { "key": 15,  "name": "15 seconds" },
            { "key": 30,  "name": "30 seconds" },
            { "key": 60,  "name": "1 minute" },
            { "key": 120, "name": "2 minutes" },
            { "key": 300, "name": "5 minutes" }
        ]
        currentKey: root.editInitialAnimationSeconds
        onSelected: key => root.editInitialAnimationSeconds = key
        defaultValue: Math.max(
            1,
            Math.round(
                (pluginApi?.manifest?.metadata?.defaultSettings?.initialAnimationMs ?? 120000) / 1000
            )
        )
        minimumWidth: 200
    }

    NComboBox {
        label: "Idle chomp interval"
        description: "How often Pac-Man chomps when already up to date."
        model: [
            { "key": 5,   "name": "5 seconds" },
            { "key": 10,  "name": "10 seconds" },
            { "key": 15,  "name": "15 seconds" },
            { "key": 30,  "name": "30 seconds" },
            { "key": 60,  "name": "1 minute" }
        ]
        currentKey: root.editIdleChompSeconds
        onSelected: key => root.editIdleChompSeconds = key
        defaultValue: Math.max(
            1,
            Math.round(
                (pluginApi?.manifest?.metadata?.defaultSettings?.idleChompMs ?? 30000) / 1000
            )
        )
        minimumWidth: 200
    }

    NDivider { Layout.fillWidth: true }

    NToggle {
        label: "Use themed idle icon color"
        description: "When disabled, the up-to-date Pac-Man icon uses a fixed neutral color instead of the current theme color."
        checked: root.editUseThemedIdleColor
        onToggled: c => root.editUseThemedIdleColor = c
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.useThemedIdleColor ?? true
    }

    NToggle {
        label: "Show idle pellet"
        description: "Displays the small pellet in the up-to-date idle state."
        checked: root.editShowIdlePellet
        onToggled: c => root.editShowIdlePellet = c
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showIdlePellet ?? true
    }

    Item { Layout.fillHeight: true }
}
