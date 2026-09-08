import QtQuick
import Quickshell
import "../Components/Cards" as Cards
import "../Models" as Models
import "../../Theme"

PathView {
    id: root

    width: Metrics.appCardWidth
    height: 400
    anchors.centerIn: parent
    clip: true
    interactive: true

    property string filterText: ""
    property int minRepeats: pathItemCount * 2

    // Owns the raw, filtered app data.
    property var appModel: Models.AppModel {}

    model: ListModel {
        id: circularModel
    }

    function moveUp() {
        root.decrementCurrentIndex();
    }

    function moveDown() {
        root.incrementCurrentIndex();
    }

    function activateCurrent() {
        root.launchCurrent();
    }

    function launchCurrent() {
        const item = root.currentItem;
        if (!item || !item.entry)
            return;
        item.entry.execute();
        closeLauncher();
    }

    // Pads the filtered results so the PathView always has enough
    // items to loop smoothly, even with a short filtered list.
    function rebuildCircularModel() {
        circularModel.clear();

        const source = [];
        for (let i = 0; i < appModel.entries.count; i++) {
            source.push(appModel.entries.get(i).entryObject);
        }

        if (source.length === 0)
            return;

        let i = 0;
        while (circularModel.count < Math.max(source.length, minRepeats)) {
            circularModel.append({ entryObject: source[i % source.length] });
            i++;
        }

        root.currentIndex = 0;
    }

    onFilterTextChanged: {
        appModel.filterText = root.filterText;
        rebuildCircularModel();
    }

    // DesktopEntries scans .desktop files asynchronously, so appModel.entries
    // is very likely still empty at Component.onCompleted below. This is what
    // actually populates the list once that scan finishes.
    Connections {
        target: root.appModel
        function onRefreshed() {
            root.rebuildCircularModel();
        }
    }

    Component.onCompleted: rebuildCircularModel()

    pathItemCount: 7
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapToItem

    path: Path {
        startX: root.width / 2
        startY: 0
        PathLine {
            x: root.width / 2
            y: root.height
        }
    }

    // Wheel-to-navigate, but let clicks fall through to delegates below.
    MouseArea {
        anchors.fill: parent
        z: 999
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (wheel.angleDelta.y < 0)
                root.incrementCurrentIndex();
            wheel.accepted = true;
        }
        onPressed: mouse => {
            mouse.accepted = false;
        }
    }

    delegate: Item {
        id: delegateItem
        width: root.width
        height: Metrics.appCardHeight
        property var entry: model.entryObject
        property bool isCurrentItem: PathView.isCurrentItem

        Cards.AppCard {
            anchors.fill: parent
            isSelected: delegateItem.isCurrentItem
            title: delegateItem.entry ? delegateItem.entry.name : ""
            iconSource: delegateItem.entry && delegateItem.entry.icon
                        ? (Quickshell.iconPath(delegateItem.entry.icon, true) || "")
                        : ""

            onFocused: root.currentIndex = index
            onActivated: {
                root.currentIndex = index;
                root.launchCurrent();
            }
        }
    }
}
