import QtQuick

// Personal, hardcoded favorites list. Not intended to be dynamic/config-driven —
// edit directly here to change what shows in the launcher's top carousel.
ListModel {
    id: root

    ListElement {
        name: "Steam"
        icon: "steam"
        appCommand: "steam"
        nSlot: 1
    }
    ListElement {
        name: "Zen Browser"
        icon: "zen-browser"
        appCommand: "zen-browser"
        nSlot: 2
    }
    ListElement {
        name: "Gram"
        icon: "/usr/share/icons/gram.png"
        appCommand: "gram"
        nSlot: 3
    }
    ListElement {
        name: "Octopi CacheCleaner"
        icon: "octopi"
        appCommand: "octopi-cachecleaner"
        nSlot: 4
    }
    ListElement {
        name: "Krita"
        icon: "krita"
        appCommand: "krita"
        nSlot: 5
    }
    ListElement {
        name: "LibreWolf"
        icon: "librewolf"
        appCommand: "librewolf"
        nSlot: 6
    }
}
