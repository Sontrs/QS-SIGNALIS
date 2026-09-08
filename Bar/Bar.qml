import QtQuick
import Quickshell
import Quickshell.Wayland
import "./Modules" as Modules
import "../Theme"


// Mimics waybar left/right modules.
Variants {
    id: barRoot
    model: Quickshell.screens

    // Bubbled up from whichever monitor's Power module was actually
    // clicked — Bar's file root is this Variants (one PanelWindow
    // delegate per screen), so a signal fired inside a delegate needs an
    // explicit outer id to reach shell.qml through, rather than the
    // usual bare `root.xRequested()` a single-window component could get
    // away with.
    signal powerRequested()

    PanelWindow {
        id: root
        property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        // Reserves screen space by default (unlike shell.qml's anchorWindow,
        // which explicitly opts out via ExclusionMode.Ignore since it's not
        // really "using" its space) — exactly what a real bar wants, so no
        // exclusionMode override needed here.
        implicitHeight: Metrics.barHeight
        color: "transparent"

        // === Background ===
        Rectangle {
            anchors.fill: parent
            color: Colors.bgBase
        }

        // === Bottom accent line ===
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Metrics.borderThick
            color: Colors.redAccent
        }

        // === Left-aligned modules, left to right ===
        Row {
            id: leftModules
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Modules.Workspaces {}
            Modules.IdleInhibitorButton { window: root }
            Modules.Clock {}
            Modules.Backlight {}
        }

        // === Right-aligned modules, left to right within the group ===
        Row {
            id: rightModules
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Modules.Storage {}
            Modules.Temperature {}
            Modules.Memory {}
            Modules.Cpu {}
            Modules.Battery {}
            Modules.Volume {}
            Modules.Network {}
            Modules.Tray { window: root }
            Modules.Power { onPowerRequested: barRoot.powerRequested() }
        }
    }
}
