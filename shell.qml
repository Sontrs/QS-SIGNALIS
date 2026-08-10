import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./Launcher"
import "./Logout"
import "./Notifications"

ShellRoot {
    id: root

    // === Panel open/closed state ===
    // Lives here (not inside Launcher/Logout themselves) because this is
    // the one thing that has to be always-resident for IpcHandler to be
    // reachable at all — you can't lazily load the thing that's
    // responsible for lazily loading everything else.
    property bool launcherOpen: false
    property bool logoutOpen: false

    // === IPC targets ===
    // Bind these from hyprland.lua with e.g.:
    //   hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
    //   hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call logout toggle"))
    // `qs ipc show` lists whatever targets are currently registered, handy
    // for checking these actually loaded.
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }
    }

    IpcHandler {
        target: "logout"

        function toggle(): void {
            root.logoutOpen = !root.logoutOpen;
        }
    }

    // Exists purely as an anchor reference point for AppLauncher's
    // PopupWindow — never meant to actually receive input. mask: Region {}
    // (an empty region) makes the *entire* surface click-through; without
    // it, a fullscreen PanelWindow's whole surface is input-catching by
    // default regardless of visual transparency, which is what was eating
    // every click on the desktop the whole time the shell was running.
    PanelWindow {
        id: anchorWindow
        implicitWidth: Screen.width
        implicitHeight: Screen.height
        visible: true
        color: "transparent"
        mask: Region {}

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
    }

    // AppLauncher's root is a PopupWindow (not an Item), so per Quickshell's
    // own guidance this is a LazyLoader rather than a plain Loader. Fully
    // unloads on close instead of just hiding — costs ~nothing while idle.
    // For quick visual testing without Hyprland/IPC at all, temporarily
    // change the line below to `property bool launcherOpen: true`.
    LazyLoader {
        active: root.launcherOpen

        AppLauncher {
            anchorTarget: anchorWindow
            onCloseRequested: root.launcherOpen = false
        }
    }

    // WLogout's root IS an Item, so this one's a plain Loader instead.
    // Real shutdown/reboot/logout/lock commands — swapped in from the
    // previous working version. hyprshutdown is presumably a script you
    // already have; not something I'm assuming exists.
    Loader {
        active: root.logoutOpen

        sourceComponent: Component {
            WLogout {
                onCloseRequested: root.logoutOpen = false

                LogoutButton {
                    command: "hyprlock"
                    keybind: Qt.Key_L
                    text: "LOCK"
                    label: "<<錠前>>"
                }
                LogoutButton {
                    command: "hyprshutdown"
                    keybind: Qt.Key_E
                    text: "LOGOUT"
                    label: "<<退場>>"
                }
                LogoutButton {
                    command: "poweroff"
                    keybind: Qt.Key_P
                    text: "SHUTDOWN"
                    label: "<<閉鎖>>"
                }
                LogoutButton {
                    command: "reboot"
                    keybind: Qt.Key_R
                    text: "REBOOT"
                    label: "<<再起動>>"
                }
            }
        }
    }

    // Untouched — stays data-driven off the notification server's own
    // tracked count, no bind/IPC/lazy-loading needed here.
    NotificationPopup {
        id: notificationPopup
    }
}
