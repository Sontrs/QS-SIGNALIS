pragma Singleton

import Quickshell
import "./trie.js" as TrieLib

/**
 * Wrapper Singleton para AppLauncherTrie.
 * Mantiene una instancia del trie y expone su API al resto de QuickShell.
 *
 * Uso desde cualquier componente:
 *   AppTrie.insert("Firefox", { exec: "firefox", icon: "firefox" })
 *   AppTrie.search("fir", 8)  // -> [{ name, meta }]
 */
Singleton {
    id: root

    property var _trie: TrieLib.AppTrie ? new TrieLib.AppTrie() : null

    function insert(name, meta) {
        return _trie.insert(name, meta)
    }

    function search(prefix, limit) {
        if (!prefix || prefix.trim() === "") return []
        return _trie.search(prefix, limit || 10)
    }

    function remove(name) {
        return _trie.remove(name)
    }

    function clear() {
        return _trie.clear()
    }

    function allApps() {
        return _trie.allApps()
    }
}
