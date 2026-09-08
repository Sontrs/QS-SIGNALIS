pragma Singleton

import QtQuick

QtObject {
    // === Spacing ===
    readonly property int sizeTiny: 4
    readonly property int sizeSmall: 8
    readonly property int sizeMedium: 12
    readonly property int sizeLarge: 16
    readonly property int sizeXLarge: 24

    // === Frame geometry ===
    readonly property int cutSizeSmall: 6
    readonly property int cutSizeMedium: 8
    readonly property int cutSizeLarge: 12

    readonly property int borderThin: 1
    readonly property int borderNormal: 2
    readonly property int borderThick: 3

    // === Favorite cards ===
    readonly property int favoriteCardWidth: 170
    readonly property int favoriteCardHeight: 120

    // === Launcher cards ===
    readonly property int appCardWidth: 970
    readonly property int appCardHeight: 50

    // === Icons ===
    readonly property int iconSmall: 16
    readonly property int iconMedium: 32
    readonly property int iconLarge: 64

    // === Navigation arrows ===
    // The launcher's prev/next favorites buttons
    readonly property int arrowSize: 100

    // === Search bar ===
    readonly property int searchBarHeight: 50

    // === Typography spacing ===
    readonly property int textInsetSmall: 4
    readonly property int textInsetMedium: 8
    readonly property int textInsetLarge: 12

    // === Animation timings ===
    readonly property int animFast: 100
    readonly property int animNormal: 200
    readonly property int animSlow: 350

    // === Notifications ===
    readonly property int notificationCardWidth: 420
    // Outer popup container's thick top bar — holds the "STATUS" title text,
    // so it needs real height to comfortably fit it.
    readonly property int notificationPopupHeaderHeight: 28
    // Each individual card's thick top bar — urgency-colored, no text, so
    // it can stay thin like the launcher/logout accent bars elsewhere.
    readonly property int notificationCardTopBarHeight: 8

    // === Bar ===
    readonly property int barHeight: 32
}
