import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginApi: null

    property int updateCount: 0
    property var packageList: []
    property bool hasUpdates: updateCount > 0
    property string lastError: ""
    property date lastCheckedAt: new Date(0)

    property string lastPacmanLogStamp: ""
    property bool pacmanLogInitialized: false

    readonly property string pluginId: pluginApi?.manifest?.id ?? "update-checker"
    readonly property string pluginDir: Quickshell.env("HOME") + "/.config/noctalia/plugins/" + pluginId

    readonly property int checkIntervalMs:
        pluginApi?.pluginSettings?.checkIntervalMs
        ?? pluginApi?.manifest?.metadata?.defaultSettings?.checkIntervalMs
        ?? 7200000

    function runCheck() {
        if (checker.running) {
            return;
        }

        checker.running = true;
    }

    function parsePayload(payload) {
        try {
            const data = JSON.parse((payload || "").trim());
            root.updateCount = Number(data.count || 0);
            root.packageList = Array.isArray(data.packages) ? data.packages : [];
            root.lastError = "";
            root.lastCheckedAt = new Date();
        } catch (e) {
            root.lastError = "Failed to parse update data";
            console.warn("[update-checker] JSON parse error:", e);
        }
    }

    function launchUpdate() {
        if (!updateLauncher.running) {
            updateLauncher.running = true;
        }
    }

    function handlePacmanLogStamp(stamp) {
        const normalized = (stamp || "").trim();

        if (!normalized)
            return;

        if (!root.pacmanLogInitialized) {
            root.lastPacmanLogStamp = normalized;
            root.pacmanLogInitialized = true;
            return;
        }

        if (normalized === root.lastPacmanLogStamp)
            return;

        root.lastPacmanLogStamp = normalized;
        pacmanDebounce.restart();
    }

    Timer {
        id: refreshTimer
        interval: root.checkIntervalMs
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.runCheck()
    }

    Timer {
        id: pacmanLogPollTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!pacmanLogStat.running)
                pacmanLogStat.running = true;
        }
    }

    Timer {
        id: pacmanDebounce
        interval: 2000
        repeat: false
        onTriggered: root.runCheck()
    }

    Process {
        id: checker
        command: [root.pluginDir + "/updates-check.sh"]
        stdout: StdioCollector {
            id: checkerStdout
        }
        stderr: StdioCollector {
            id: checkerStderr
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.lastError = (checkerStderr.text || "Update check failed").trim();
                root.lastCheckedAt = new Date();
                console.warn("[update-checker] backend failed:", exitCode, exitStatus, root.lastError);
                return;
            }

            root.parsePayload(checkerStdout.text);
        }
    }

    Process {
        id: pacmanLogStat
        command: [
            "bash",
            "-lc",
            "if [ -e /var/log/pacman.log ]; then stat -c '%Y:%s' /var/log/pacman.log; else echo ''; fi"
        ]
        stdout: StdioCollector {
            id: pacmanLogStdout
        }
        stderr: StdioCollector {
            id: pacmanLogStderr
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("[update-checker] pacman log stat failed:", exitCode, exitStatus, pacmanLogStderr.text);
                return;
            }

            root.handlePacmanLogStamp(pacmanLogStdout.text);
        }
    }

    Process {
        id: updateLauncher
        command: [
            "kitty",
            "--title",
            "System Update",
            "-e",
            "bash",
            "-lc",
            "sudo pacman -Syu; echo ''; echo 'Update complete. Press Enter to close.'; read"
        ]
    }
}
