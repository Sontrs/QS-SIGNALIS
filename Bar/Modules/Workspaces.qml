import QtQuick
import Quickshell.Hyprland
import "../../Theme"

// Mirrors waybar's hyprland/workspaces module: all outputs (every
// workspace shows on every monitor's bar, not filtered to the monitor
// it's currently on), all workspaces that currently exist (waybar's
// active-only: false just means "don't hide populated-but-unfocused
// workspaces" — Hyprland only reports workspaces that exist at all in the
// first place, so no extra filtering is needed to match that), same Kanji
// numeral glyphs 1-10 the waybar config used. Hyprland.workspaces is
// already sorted by id (confirmed in Quickshell's own docs), so no manual
// sort needed either.
Row {
    id: root
    spacing: 0

    readonly property var kanjiNumerals: ({
        "1": "一", "2": "二", "3": "三", "4": "四", "5": "五",
        "6": "六", "7": "七", "8": "八", "9": "九", "10": "十"
    })

    Repeater {
        model: Hyprland.workspaces.values

        Rectangle {
            id: delegate
            required property var modelData

            // "active" = shown on its own monitor right now — the right
            // read for an all-outputs bar, since every monitor's currently
            // displayed workspace should highlight, not just whichever one
            // monitor happens to be system-focused (that's "focused",
            // deliberately not used here).
            readonly property bool isActive: modelData.active
            readonly property string label: root.kanjiNumerals[String(modelData.id)] ?? String(modelData.id)

            width: 28
            height: 24
            color: isActive
                ? Colors.redAccent
                : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")

            Behavior on color {
                ColorAnimation {
                    duration: Metrics.animFast
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: delegate.label
                color: delegate.isActive ? Colors.bgBase : Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                // activate() dispatches by name internally (confirmed in
                // Quickshell's docs), so this is correct even for named/
                // negative-id workspaces, not just plain numbered ones.
                onClicked: delegate.modelData.activate()
            }
        }
    }
}
