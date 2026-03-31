import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen?.name ?? ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
    readonly property var main: pluginApi?.mainInstance ?? null

    property bool initialAnimActive: false
    property bool hoverAnimActive: false
    property bool isEating: true
    property bool mouthOpen: true
    property int eatenChars: 0

    readonly property bool hasUpdates: (main?.updateCount ?? 0) > 0
    readonly property bool showFullAnim: initialAnimActive || hoverAnimActive

    readonly property string displayString:
        hasUpdates
        ? ((main?.updateCount ?? 0) + " update" + ((main?.updateCount ?? 0) !== 1 ? "s" : ""))
        : "✓ Up to date"

    readonly property var displayChars: displayString.split("")
    readonly property int charCount: Math.max(1, displayChars.length)
    readonly property real textWidth: Math.max(1, textMetrics.width)
    readonly property real charWidth: textWidth / charCount
    readonly property real pacBaseSize: Math.max(18, barFontSize + 8)

    readonly property real pacX: {
        if (!showFullAnim)
            return 0;
        return eatenChars * charWidth;
    }

    readonly property real contentWidth: pacBaseSize + textWidth + Style.marginM * 3
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    function resetAnimation() {
        eatenChars = 0;
        isEating = true;
        mouthOpen = true;
        pacCanvas.requestPaint();
    }

    function beginInitialAnimation() {
        if (!hasUpdates)
            return;

        initialAnimActive = true;
        hoverAnimActive = false;
        resetAnimation();
        initialAnimTimer.restart();
        eatPrintAnim.restart();
    }

    function stopFullAnimation() {
        eatPrintAnim.stop();
        initialAnimActive = false;
        hoverAnimActive = false;
        resetAnimation();
    }

    function restartHoverAnimation() {
        if (!hasUpdates)
            return;

        initialAnimActive = false;
        initialAnimTimer.stop();
        hoverAnimActive = true;
        eatPrintAnim.stop();
        resetAnimation();
        eatPrintAnim.restart();
    }

    function buildTooltip() {
        if (!main)
            return "Update Checker";

        if (main.lastError && main.lastError.length > 0)
            return "Update Checker\n" + main.lastError;

        if (!hasUpdates)
            return "System is up to date";

        return main.updateCount + " pending update" + (main.updateCount !== 1 ? "s" : "")
               + "\nHover to replay animation\nClick to view packages";
    }

    function characterVisible(index) {
        if (!showFullAnim)
            return true;

        return index >= eatenChars;
    }

    Connections {
        target: main

        function onUpdateCountChanged() {
            if (!root.main)
                return;

            if (root.main.updateCount > 0)
                root.beginInitialAnimation();
            else
                root.stopFullAnimation();
        }
    }

    TextMetrics {
        id: textMetrics
        font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font Mono, Symbols Nerd Font"
        font.pointSize: root.barFontSize
        text: root.displayString
    }

    Timer {
        id: initialAnimTimer
        interval: pluginApi?.pluginSettings?.initialAnimationMs
                  ?? pluginApi?.manifest?.metadata?.defaultSettings?.initialAnimationMs
                  ?? 300000
        repeat: false
        onTriggered: {
            root.initialAnimActive = false;
            eatPrintAnim.stop();
            root.resetAnimation();
        }
    }

    Timer {
        id: moveChompTimer
        interval: 90
        repeat: true
        running: root.showFullAnim
        onTriggered: {
            root.mouthOpen = !root.mouthOpen;
            pacCanvas.requestPaint();
        }
    }

    Timer {
        id: chompTimer
        interval: pluginApi?.pluginSettings?.idleChompMs
                  ?? pluginApi?.manifest?.metadata?.defaultSettings?.idleChompMs
                  ?? 30000
        repeat: true
        running: !root.showFullAnim
        onTriggered: chompAnim.restart()
    }

    SequentialAnimation {
        id: chompAnim
        ScriptAction { script: { root.mouthOpen = false; pacCanvas.requestPaint(); } }
        PauseAnimation { duration: 160 }
        ScriptAction { script: { root.mouthOpen = true; pacCanvas.requestPaint(); } }
        PauseAnimation { duration: 160 }
        ScriptAction { script: { root.mouthOpen = false; pacCanvas.requestPaint(); } }
        PauseAnimation { duration: 160 }
        ScriptAction { script: { root.mouthOpen = true; pacCanvas.requestPaint(); } }
    }

    SequentialAnimation {
        id: eatPrintAnim
        loops: Animation.Infinite

        PropertyAction { target: root; property: "isEating"; value: true }
        NumberAnimation {
            target: root
            property: "eatenChars"
            from: 0
            to: root.charCount
            duration: Math.max(1000, root.charCount * 140)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 140 }

        PropertyAction { target: root; property: "isEating"; value: false }
        NumberAnimation {
            target: root
            property: "eatenChars"
            from: root.charCount
            to: 0
            duration: Math.max(1000, root.charCount * 125)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 550 }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            anchors.centerIn: parent
            spacing: Style.marginS

            Item {
                id: track
                width: root.pacBaseSize + root.textWidth
                height: Math.max(root.pacBaseSize, labelRow.implicitHeight)

                Canvas {
                    id: pacCanvas
                    width: root.pacBaseSize
                    height: root.pacBaseSize
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.showFullAnim ? root.pacX : 0
                    y: root.showFullAnim ? Math.sin((root.eatenChars / root.charCount) * Math.PI * 4) * 1.2 : 0
                    antialiasing: true
                    z: 2

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const w = width;
                        const h = height;
                        const r = Math.min(w, h) / 2 - 1;
                        const cx = w / 2;
                        const cy = h / 2;

                        const activePacColor = "#F6D32D";
                        const idlePacColor =
                            Color?.mPrimary
                            ?? Color?.mOnSurface
                            ?? Style?.textColor
                            ?? "#E6E6E6";

                        const pacColor = (root.showFullAnim || root.hasUpdates)
                                         ? activePacColor
                                         : idlePacColor;

                        if (!root.hasUpdates) {
                            const mouthAngle = root.mouthOpen ? 0.24 : 0.05;

                            const pelletX = w - 3;
                            const pelletY = cy;
                            const pelletR = Math.max(1.2, r * 0.10);

                            ctx.fillStyle = "rgba(255,255,255,0.55)";
                            ctx.beginPath();
                            ctx.arc(pelletX, pelletY, pelletR, 0, Math.PI * 2);
                            ctx.fill();

                            ctx.fillStyle = pacColor;
                            ctx.beginPath();
                            ctx.moveTo(cx, cy);
                            ctx.arc(cx, cy, r, mouthAngle, Math.PI * 2 - mouthAngle, false);
                            ctx.closePath();
                            ctx.fill();

                            ctx.fillStyle = "#111111";
                            ctx.beginPath();
                            ctx.arc(cx + r * 0.12, cy - r * 0.40, Math.max(1.2, r * 0.10), 0, Math.PI * 2);
                            ctx.fill();
                            return;
                        }

                        const facingLeft = root.showFullAnim && !root.isEating;
                        const mouthAngle = root.mouthOpen ? 0.75 : 0.16;

                        ctx.save();
                        if (facingLeft) {
                            ctx.translate(w, 0);
                            ctx.scale(-1, 1);
                        }

                        ctx.fillStyle = pacColor;
                        ctx.beginPath();
                        ctx.moveTo(cx, cy);
                        ctx.arc(cx, cy, r, mouthAngle, Math.PI * 2 - mouthAngle, false);
                        ctx.closePath();
                        ctx.fill();

                        ctx.fillStyle = "#111111";
                        ctx.beginPath();
                        ctx.arc(cx + r * 0.10, cy - r * 0.42, Math.max(1.2, r * 0.11), 0, Math.PI * 2);
                        ctx.fill();

                        ctx.restore();
                    }
                }

                Item {
                    id: textContainer
                    x: root.pacBaseSize + Style.marginS / 2
                    width: root.textWidth
                    height: labelRow.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter
                    clip: false
                    z: 1

                    Row {
                        id: labelRow
                        spacing: 0
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: root.charCount

                            Item {
                                width: root.charWidth
                                height: charLabel.implicitHeight

                                NText {
                                    id: charLabel
                                    anchors.centerIn: parent
                                    text: root.displayChars[index]
                                    visible: root.characterVisible(index)
                                    opacity: visible ? 1.0 : 0.0
                                    color: Color.mOnSurface
                                    pointSize: root.barFontSize
                                    font.weight: Font.Medium
                                    font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font Mono, Symbols Nerd Font"
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.max(2, root.barFontSize * 0.16)
                                    height: width
                                    radius: width / 2
                                    visible: root.showFullAnim
                                             && root.isEating
                                             && index === root.eatenChars
                                             && root.displayChars[index] !== " "
                                    color: Color.mOnSurface
                                    opacity: 0.35
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 99
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            TooltipService.show(root, root.buildTooltip(), BarService.getTooltipDirection());

            if (root.hasUpdates)
                root.restartHoverAnimation();
        }

        onExited: {
            TooltipService.hide();

            if (root.hoverAnimActive) {
                root.hoverAnimActive = false;
                eatPrintAnim.stop();
                root.resetAnimation();

                if (root.hasUpdates)
                    chompTimer.restart();
            }
        }

        onClicked: {
            if (!pluginApi || !root.hasUpdates)
                return;

            pluginApi.togglePanel(root.screen, root);
        }
    }
}
