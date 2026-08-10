import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Theme"
import "../Theme/Effects" as Effects

Item {
    id: root

    // Deliberately not Colors.bgBase (#202020) — the old code used pure
    // black specifically as a full-screen backdrop for the CRT takeover,
    // distinct from the launcher panels' dark grey.
    property color backgroundColor: "#000000"
    property color buttonColor: Colors.redAccent
    property color buttonHoverColor: Colors.whiteAccent
    default property list<LogoutButton> buttons

    // Emitted instead of hiding directly — the owning Loader (see
    // shell.qml) tears the whole thing down on close instead of just
    // setting visible: false, so idle logout screens cost nothing. Same
    // reasoning as AppLauncher.closeRequested.
    signal closeRequested

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: w
            property var modelData
            screen: modelData
            implicitWidth: screen.width
            implicitHeight: screen.height
            visible: true

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeRequested();
                    } else {
                        for (let i = 0; i < root.buttons.length; i++) {
                            if (event.key === root.buttons[i].keybind)
                                root.buttons[i].exec();
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent

                // === Background fade-in ===
                Rectangle {
                    anchors.fill: parent
                    color: root.backgroundColor
                    opacity: 0
                    z: 0

                    NumberAnimation on opacity {
                        from: 0
                        to: 0.95
                        duration: 300
                        easing.type: Easing.OutQuad
                    }
                }

                // === Main content (sampled by CRTOverlay below, not drawn directly) ===
                Item {
                    id: mainContent
                    anchors.fill: parent

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeRequested()

                        ColumnLayout {
                            id: layoutRoot
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.05
                            spacing: 10
                            width: parent.width * 0.85
                            // No explicit height needed: every child below now
                            // has a real preferred/fixed height (no fillHeight
                            // anywhere in this tree anymore), so the circular-
                            // dependency problem that required an explicit
                            // height here previously no longer applies. This
                            // sizes tightly to its actual content instead of
                            // leaving empty space below the buttons.

                            // ---------- LABELS ----------
                            // Static — never animated on its own. It just sits
                            // behind/underneath the falling button row, so it
                            // reads as "revealed" once the fall settles rather
                            // than popping in.
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                columnSpacing: 50
                                Layout.preferredHeight: 40

                                Repeater {
                                    model: root.buttons
                                    delegate: Item {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        Layout.bottomMargin: 5

                                        Text {
                                            text: modelData.label
                                            font.family: Fonts.currentFamily
                                            font.bold: true
                                            font.letterSpacing: 5
                                            font.pointSize: 20
                                            color: root.buttonColor
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.centerIn: parent

                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                PauseAnimation { duration: 3000 + Math.random() * 4000 }
                                                NumberAnimation { to: 0.7; duration: 50 }
                                                NumberAnimation { to: 1.0; duration: 50 }
                                            }
                                        }
                                    }
                                }
                            }

                            // ---------- DIVIDER ----------
                            // Outer item handles the reveal-near-the-end fade
                            // (tied to the fall's progress); inner Rectangle
                            // keeps its own independent looping "breathing"
                            // animation. Kept as two separate opacities
                            // (rather than both on one Rectangle) because a
                            // property binding and a running Animation
                            // targeting the same property fight each other —
                            // QML just drops the binding once the animation
                            // starts touching that property.
                            Item {
                                Layout.fillWidth: true
                                height: 3
                                opacity: Math.max(0, Math.min(1, (buttonDropRow.progress - 0.6) / 0.4))

                                Rectangle {
                                    anchors.fill: parent
                                    color: root.buttonColor

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.8; duration: 1500 }
                                        NumberAnimation { to: 1.0; duration: 1500 }
                                    }
                                }
                            }

                            // ---------- BUTTONS (falling entrance) ----------
                            ButtonDropRow {
                                id: buttonDropRow
                                Layout.fillWidth: true
                                // Sized to exactly fit the settled button
                                // (not fillHeight): the old fillHeight left a
                                // big empty gap between the divider above and
                                // where the buttons actually landed, since
                                // they were bottom-aligned within a much
                                // taller box than they needed.
                                Layout.preferredHeight: buttonDropRow.buttonHeight

                                buttons: root.buttons
                                buttonColor: root.buttonColor
                                buttonHoverColor: root.buttonHoverColor

                                // Overrides the component's own default
                                // (10% of its own height, which — now that
                                // it's sized tightly to the button — would
                                // barely fall at all). This targets true
                                // screen-middle instead: layoutRoot.y +
                                // buttonDropRow.y is this component's actual
                                // offset from mainContent's top, so
                                // subtracting that from half of mainContent's
                                // height gives the right LOCAL start position
                                // (deliberately negative — renders above this
                                // component's own bounds, which QML allows
                                // by default since nothing here clips).
                                dropStartY: (mainContent.height * 0.5) - layoutRoot.y - buttonDropRow.y

                                onActivated: index => root.buttons[index].exec()
                            }
                        }
                    }
                }

                // === CRT material: curvature/aberration + scanlines + grain,
                // at full strength — this is the fullscreen takeover the
                // look was originally built for. Flicker off per request.
                // See Theme/Effects/CRTStack.qml. ===
                Effects.CRTStack {
                    anchors.fill: parent
                    sourceItem: mainContent
                    strength: 1.0
                    flickerEnabled: false
                }
            }
        }
    }
}
