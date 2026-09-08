//@ pragma UseQApplication

// Some tray apps' context menus render as a "PlatformMenuEntry" — a real
// native QWidget-based menu, not a DBusMenu Quickshell can draw itself.
// Quickshell defaults to QGuiApplication (it's normally pure QtQuick, no
// widgets needed), and those platform menus fail outright without this —
// confirmed directly from Quickshell's own runtime error pointing at
// this exact fix. Has to be a `//@ pragma` comment rather than a normal
// QML `pragma` statement, and has to be the literal first thing in the
// root file — this decides which QApplication subclass the process
// starts as, before the QML engine itself even exists to parse a normal
// pragma statement.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "./Launcher"
import "./Logout"
import "./Notifications"
import "./Bar"

ShellRoot {
    id: root

    // === Panel open/closed state ===
    // Lives here (not inside Launcher/Logout themselves) because this is
    // the one thing that has to be always-resident for IpcHandler to be
    // reachable at all — you can't lazily load the thing that's
    // responsible for lazily loading everything else.
    property bool launcherOpen: false
    property bool logoutOpen: false

    // Falls back to the first screen if Hyprland hasn't reported a focused
    // monitor yet (e.g. queried too early at startup).
    function focusedScreen() {
        const focused = Hyprland.focusedMonitor;
        if (!focused)
            return Quickshell.screens[0];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focused.name)
                return Quickshell.screens[i];
        }
        return Quickshell.screens[0];
    }

    // === IPC targets ===

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!root.launcherOpen)
                anchorWindow.screen = root.focusedScreen();

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
    // PopupWindow. mask: Region {} (an empty region) makes the
    // entire surface click-through.

    // screen defaults to the primary screen at startup and gets
    // reassigned to whichever monitor was focused at the moment the
    // launcher IPC toggle actually opens it (see the IpcHandler above)
    // not a live binding to the focused monitor, since that would make an
    // already-open launcher jump screens if focus moved elsewhere while
    // it's still visible, which isn't what was asked for.
    PanelWindow {
        id: anchorWindow
        screen: Quickshell.screens[0]
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

    // AppLauncher's root is a PopupWindow so per Quickshell's own guidance
    // this is a LazyLoader rather than a plain Loader.
    LazyLoader {
        active: root.launcherOpen

        AppLauncher {
            anchorTarget: anchorWindow
            onCloseRequested: root.launcherOpen = false
        }
    }

    // WLogout's root IS an Item, so this one's a plain Loader instead.
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

    // Data-driven off the notification server's own tracked count, no
    // bind/IPC/lazy-loading needed here.
    NotificationPopup {
        id: notificationPopup
    }

    // Plain instantiation, not a Loader/LazyLoader.
    Bar {
        id: bar
        onPowerRequested: root.logoutOpen = !root.logoutOpen
    }
}
