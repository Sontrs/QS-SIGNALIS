import QtQuick
import Quickshell
import "../Components/Cards" as Cards
import "../Models" as Models
import "../../Theme"

Item {
    id: root

    anchors.centerIn: parent
    width: parent.width - Metrics.sizeXLarge * 2.5
    height: parent.height

    // Exposed so external arrow buttons (in AppLauncher.qml) can
    // disable/dim themselves when the current slot has nothing to launch.
    readonly property bool currentHasCommand: carousel.currentItem
                                               ? !carousel.currentItem.isEmpty
                                               : false

    function next() {
        carousel.incrementCurrentIndex();
    }

    function previous() {
        carousel.decrementCurrentIndex();
    }

    Models.FavoritesModel {
        id: favoritesModel
    }

    // === Slot indicator dots ===
    Row {
        id: indicatorRow
        spacing: Metrics.sizeSmall - 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        Repeater {
            model: favoritesModel.count

            Rectangle {
                width: Metrics.sizeXLarge
                height: Metrics.sizeSmall
                antialiasing: true

                readonly property bool hasCommand: {
                    const cmd = favoritesModel.get(index).appCommand;
                    return cmd !== undefined && cmd.length > 0;
                }
                readonly property bool isCurrent: index === carousel.currentIndex

                color: isCurrent && hasCommand ? Colors.whiteAccent
                       : hasCommand ? Colors.redAccent
                       : Colors.bgBase

                border.width: 1.2
                border.color: isCurrent ? Colors.whiteAccent
                              : hasCommand ? Colors.redAccent
                              : Colors.grayAccent
            }
        }
    }

    // === Carousel ===
    PathView {
        id: carousel
        interactive: false
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        model: favoritesModel
        pathItemCount: 5

        snapMode: PathView.SnapOneItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5

        path: Path {
            startX: 0
            startY: carousel.height / 2
            PathLine {
                x: carousel.width
                y: carousel.height / 2
            }
        }

        delegate: Item {
            id: delegateItem
            width: Metrics.favoriteCardWidth
            height: Metrics.favoriteCardHeight

            readonly property bool isEmpty: !appCommand || appCommand.length === 0

            Cards.FavoriteCard {
                anchors.fill: parent
                // Empty appCommand => treated as an empty slot regardless
                // of whether a name happens to be set.
                title: delegateItem.isEmpty ? "" : (model.name || "")
                iconSource: (!delegateItem.isEmpty && model.icon)
                            ? (Quickshell.iconPath(model.icon, true) || "")
                            : ""
                slotNumber: model.nSlot
                isCurrent: PathView.isCurrentItem

                onActivated: {
                    if (!delegateItem.isEmpty) {
                        Quickshell.execDetached(appCommand);
                        closeLauncher();
                    }
                }
            }
        }
    }
}
