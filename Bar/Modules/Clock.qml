import QtQuick
import Quickshell
import "../../Theme"
import "../../Components/Popups" as Popups

// Format mirrors the old waybar clock#date module: %I:%M %p   %e %b in
// strftime becomes hh:mm AP   d MMM in Qt's format tokens (AP switches hh
// to 12-hour mode automatically — Qt has no separate 12-hour-only token).
// Only real difference: %e space-pads single-digit days for alignment,
// Qt's `d` doesn't — cosmetic, not worth fighting.
//
// precision: Minutes, not the SystemClock.Seconds shown in Quickshell's
// own example — nothing here displays seconds, so there's no reason to
// repaint every second for a value that never appears.
//
// Click launches the same "kitty -e calcurse" waybar used. See chat for
// why this needs the array form, not a shell string.
//
// Tooltip calendar: plain JS Date math, no new data source needed.
// Leading blank cells (empty string, not 0 — 0 would render as a literal
// "0") pad out to whichever weekday the 1st actually falls on; no
// trailing padding since Grid just stops wherever the Repeater's model
// runs out. Today's cell picks up the red accent rather than a
// background highlight — a filled cell would need its own frame just to
// look intentional at this size, plain color change reads clearly enough
// on its own.
Rectangle {
    id: root

    property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
    }

    readonly property string calendarHeaderText: Qt.formatDateTime(root.clock.date, "yyyy MMMM")
    readonly property int todayDate: root.clock.date.getDate()

    readonly property var calendarCells: {
        const now = root.clock.date;
        const year = now.getFullYear();
        const month = now.getMonth();
        const firstWeekday = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        const cells = [];
        for (let i = 0; i < firstWeekday; i++)
            cells.push("");
        for (let d = 1; d <= daysInMonth; d++)
            cells.push(d);
        return cells;
    }

    width: label.implicitWidth + Metrics.sizeMedium * 2
    height: 24
    color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutQuad
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.clock.date, "hh:mm AP   d MMM")
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["kitty", "-e", "calcurse"])
    }

    Popups.Tooltip {
        hoverTarget: root
        hovered: mouseArea.containsMouse

        Column {
            spacing: Metrics.sizeSmall

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.calendarHeaderText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }

            Grid {
                columns: 7
                spacing: Metrics.sizeTiny

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    Text {
                        required property string modelData
                        text: modelData
                        width: Metrics.sizeXLarge
                        horizontalAlignment: Text.AlignHCenter
                        color: Colors.redAccent
                        font.family: Fonts.currentFamily
                        font.pixelSize: Fonts.small
                    }
                }

                Repeater {
                    model: root.calendarCells

                    Text {
                        required property var modelData
                        text: modelData
                        width: Metrics.sizeXLarge
                        horizontalAlignment: Text.AlignHCenter
                        color: modelData !== "" && modelData === root.todayDate ? Colors.redAccent : Colors.textPrimary
                        font.family: Fonts.currentFamily
                        font.pixelSize: Fonts.small
                    }
                }
            }
        }
    }
}
