import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 560 * Style.uiScaleRatio
    property real contentPreferredHeight: 480 * Style.uiScaleRatio
    readonly property var main: pluginApi?.mainInstance ?? null

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            radius: Style.radiusXL
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginL

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "System Updates"
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                }

                NText {
                    text: main
                          ? ((main.updateCount > 0)
                             ? (main.updateCount + " package" + (main.updateCount !== 1 ? "s" : "") + " ready to install")
                             : "Your system is up to date")
                          : "Loading update status…"
                    color: Color.mOnSurfaceVariant
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.radiusL
                color: Color.mSurfaceVariant
                border.color: Style.capsuleBorderColor
                border.width: Style.capsuleBorderWidth

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: Style.marginS

                        Repeater {
                            model: main?.packageList ?? []

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: packageRow.implicitHeight + Style.marginS * 2
                                radius: Style.radiusM
                                color: Color.mSurface
                                border.color: Style.capsuleBorderColor
                                border.width: 1

                                RowLayout {
                                    id: packageRow
                                    anchors.fill: parent
                                    anchors.margins: Style.marginS
                                    spacing: Style.marginM

                                    NText {
                                        text: modelData.name
                                        Layout.fillWidth: true
                                        color: Color.mOnSurface
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    NText {
                                        text: modelData.old + " → " + modelData.new
                                        color: Color.mOnSurfaceVariant
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: (main?.packageList?.length ?? 0) > 0 ? 0 : emptyText.implicitHeight

                            NText {
                                id: emptyText
                                anchors.centerIn: parent
                                visible: (main?.packageList?.length ?? 0) === 0
                                text: "No pending updates"
                                color: Color.mOnSurfaceVariant
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: "Check now"
                    onClicked: main?.runCheck()
                }

                NButton {
                    text: "Run update"
                    enabled: (main?.updateCount ?? 0) > 0
                    onClicked: main?.launchUpdate()
                }

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: "Close"
                    onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
                }
            }
        }
    }
}
