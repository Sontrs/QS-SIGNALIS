import QtQuick
import Quickshell

// Owns access to the system's desktop entries: sorting, filtering,
// and staying in sync when the installed-app list changes.
// Does NOT know about PathView, launching, or presentation concerns —
// those belong to the Modules that consume this.
QtObject {
    id: root

    property string filterText: ""

    // Exposed for consumption by AppList.qml (Module).
    // Each row: { entryObject: <DesktopEntry> }
    readonly property ListModel entries: ListModel {}

    // Fired whenever entries has been rebuilt — including the async
    // case where DesktopEntries finishes scanning after this component
    // has already completed. Consumers (AppList) must listen for this
    // rather than assuming entries is populated by Component.onCompleted.
    signal refreshed

    function refresh() {
        entries.clear();

        const filter = root.filterText.toLowerCase().trim();
        const apps = DesktopEntries.applications.values.slice();

        apps.sort((a, b) => {
            return a.name.localeCompare(b.name, Qt.locale(), {
                sensitivity: Qt.CaseInsensitive
            });
        });

        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            if (filter === "" || app.name.toLowerCase().includes(filter)) {
                entries.append({ entryObject: app });
            }
        }

        root.refreshed();
    }

    onFilterTextChanged: root.refresh()

    Component.onCompleted: root.refresh()

    property Connections _desktopEntriesWatcher: Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refresh();
        }
    }
}
