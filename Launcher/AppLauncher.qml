import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "./Modules" as Modules
import "../Components/Decorations" as Decorations
import "../Components/Frames" as Frames
import "../Theme"
import "../Theme/Effects" as Effects

PopupWindow {
    id: root
    implicitWidth: 1000
    implicitHeight: 700
    visible: false
    color: "transparent"

    property QtObject anchorTarget

    // Emitted instead of hiding directly — whoever instantiates this (a
    // LazyLoader, see shell.qml) owns the actual open/closed state and
    // tears the whole window down on close rather than just setting
    // visible: false. That's why closeLauncher() below no longer resets
    // visible/searchBar itself: destroying and recreating the window does
    // that for free on the next open.
    signal closeRequested

    anchor.window: anchorTarget

    // Live bindings rather than a one-shot Timer assignment: the old version
    // computed position once, 50ms after load, assuming anchorTarget.width/
    // height were already valid by then. If the compositor took longer than
    // that to report real screen dimensions, position was calculated from a
    // stale/zero size, landing the window at the top-left. This recalculates
    // automatically whenever anchorTarget's size actually changes.
    anchor.rect.x: root.anchorTarget ? (root.anchorTarget.width - root.width) / 2 : 0
    anchor.rect.y: root.anchorTarget ? (root.anchorTarget.height - root.height) / 2 : 0

    Timer {
        interval: 50
        running: true
        onTriggered: {
            if (root.anchorTarget) {
                root.visible = true;
                focusGrab.active = true;
                searchBar.input.forceActiveFocus();
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false

        onCleared: root.closeLauncher()
    }

    function closeLauncher() {
        focusGrab.active = false;
        root.closeRequested();
    }

    // === Main content (sampled by the CRT stack below, not drawn directly
    // when curvature is on) ===
    Item {
        id: mainContent
        anchors.fill: parent

        // === Top: favorites carousel + nav arrows ===
        Item {
            id: topper
            width: parent.width
            height: 155

            Decorations.ArrowButton {
                id: leftArrow
                height: parent.height
                width: 50
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                direction: Decorations.ArrowButton.Left
                leftPadding: 0
                rightPadding: 15
                active: favorites.currentHasCommand
                z: 2

                TapHandler {
                    onTapped: favorites.previous()
                }
            }

            Modules.FavoritesCarousel {
                id: favorites
                height: parent.height
                width: 900
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                z: 1
            }

            Decorations.ArrowButton {
                id: rightArrow
                height: parent.height
                width: 50
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                direction: Decorations.ArrowButton.Right
                leftPadding: 15
                rightPadding: 0
                active: favorites.currentHasCommand
                z: 3

                TapHandler {
                    onTapped: favorites.next()
                }
            }

            Rectangle {
                width: 180
                height: 130
                anchors.centerIn: parent
                color: "transparent"
                border.color: Colors.grayAccent
                border.width: Metrics.borderThin
                z: 4
            }
        }

        // === Search bar ===
        Modules.SearchBar {
            id: searchBar
            anchors.top: topper.bottom
            anchors.left: parent.left
            width: parent.width
            z: 5

            onMoveUp: appList.moveUp()
            onMoveDown: appList.moveDown()
            onEscapePressed: root.closeLauncher()
            onActivateCurrent: {
                appList.activateCurrent();
                root.closeLauncher();
            }
        }

        // === App list ===
        Item {
            anchors.top: searchBar.bottom
            anchors.topMargin: Metrics.sizeMedium - 2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Frames.CutFrame {
                anchors.fill: parent
                strokeColor: Colors.redAccent
                z: 1
            }

            Modules.AppList {
                id: appList
                anchors.centerIn: parent
                z: 2
                filterText: searchBar.text
            }

            Modules.PanelShadows {
                z: 3
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 25
                color: Colors.redAccent
                z: 4
            }
        }
    } // mainContent

    // === CRT material, texture only — curvature/aberration off. The
    // vignette darkening that comes bundled with CRTOverlay was reading as
    // an odd soft shadow around content rather than a screen curve, same
    // problem Notifications avoided by never enabling it. Scanlines/grain
    // alone still tie this to the other two surfaces. Flicker off per
    // request. ===
    Effects.CRTStack {
        anchors.fill: parent
        sourceItem: mainContent
        strength: 0.4
        curvatureEnabled: false
        flickerEnabled: false
    }
}
