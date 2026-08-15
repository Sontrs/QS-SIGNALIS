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

    // Guards against closeLauncher() re-entering itself: setting
    // focusGrab.active = false below triggers focusGrab's own onCleared,
    // which calls closeLauncher() again. Without this the fade-out
    // animation would restart mid-flight (and closeRequested would fire
    // twice) on every single close.
    property bool closing: false

    // PopupWindow has no plain `opacity` property — Wayland doesn't have a
    // universal window-opacity concept the way X11 does, so Quickshell
    // only exposes it as a Hyprland-specific attached property. Animating
    // fadeOpacity (an ordinary property, zero ambiguity) and binding the
    // attached property to follow it sidesteps any question about whether
    // a NumberAnimation can target an attached property's dotted path
    // directly. HyprlandWindow.opacity itself accepts "any number or
    // binding" per Quickshell's docs, so this live binding is exactly the
    // supported usage. Requires Hyprland >= 0.47.0 — comfortably covered.
    property real fadeOpacity: 0
    HyprlandWindow.opacity: root.fadeOpacity

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
        interval: 100
        running: true
        onTriggered: {
            if (root.anchorTarget) {
                root.visible = true;
                openAnimation.start();
                focusGrab.active = true;
                searchBar.input.forceActiveFocus();
            }
        }
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "fadeOpacity"
        from: 0
        to: 1
        duration: 150
        easing.type: Easing.OutQuad
    }

    // No `from` — always fades from whatever opacity root is actually at
    // when triggered, rather than assuming 1, so it stays correct even if
    // close is somehow requested before the open fade finished.
    NumberAnimation {
        id: closeAnimation
        target: root
        property: "fadeOpacity"
        to: 0
        duration: 120
        easing.type: Easing.InQuad
        // Only actually tear the window down once it's already invisible —
        // this is the entire point, otherwise the LazyLoader in shell.qml
        // destroys the window mid-fade and the animation never gets to be
        // seen.
        onStopped: root.closeRequested()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false

        onCleared: root.closeLauncher()
    }

    function closeLauncher() {
        if (root.closing)
            return;
        root.closing = true;
        focusGrab.active = false;
        closeAnimation.start();
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

    // === CRT material, texture only — curvature off (vignette/warp read
    // as an odd soft shadow on a small floating popup, not a screen
    // curve). Aberration now on independently — it used to be silently
    // killed by curvatureEnabled: false since both lived in one shader,
    // see Theme/Effects/CRTStack.qml. Flicker off per request. ===
    Effects.CRTStack {
        anchors.fill: parent
        sourceItem: mainContent
        strength: 0.4
        curvatureEnabled: false
        aberrationEnabled: true
        flickerEnabled: false
    }
}
