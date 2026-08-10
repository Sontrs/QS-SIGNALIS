function TrieNode() {
  this.children = {};
  this.apps = [];
  this.isEnd = false;
}

function AppTrie() {
  this.root = new TrieNode();
}

AppTrie.prototype.insert = function (name, meta) {
  var key = name.toLowerCase().trim();
  if (!key) return;

  var node = this.root;
  for (var i = 0; i < key.length; i++) {
    var ch = key[i];
    if (!node.children[ch]) node.children[ch] = new TrieNode();
    node = node.children[ch];
  }

  node.isEnd = true;
  node.apps.push({ name: name, meta: meta || {} });
};

AppTrie.prototype.search = function (prefix, limit) {
  var key = prefix.toLowerCase().trim();
  var max = limit || 10;
  var results = [];

  var node = this.root;
  for (var i = 0; i < key.length; i++) {
    var ch = key[i];
    if (!node.children[ch]) return [];
    node = node.children[ch];
  }

  this._collect(node, results, max);

  results.sort(function (a, b) {
    var aExact = a.name.toLowerCase() === key;
    var bExact = b.name.toLowerCase() === key;
    if (aExact && !bExact) return -1;
    if (!aExact && bExact) return 1;
    return a.name.localeCompare(b.name);
  });

  return results.slice(0, max);
};

AppTrie.prototype._collect = function (node, results, max) {
  if (results.length >= max) return;
  if (node.isEnd) {
    for (var i = 0; i < node.apps.length; i++) {
      if (results.length >= max) return;
      results.push(node.apps[i]);
    }
  }
  var chars = Object.keys(node.children);
  for (var j = 0; j < chars.length; j++) {
    if (results.length >= max) return;
    this._collect(node.children[chars[j]], results, max);
  }
};

AppTrie.prototype.remove = function (name) {
  var key = name.toLowerCase().trim();
  this._removeHelper(this.root, key, 0);
};

AppTrie.prototype._removeHelper = function (node, key, depth) {
  if (!node) return false;
  if (depth === key.length) {
    if (!node.isEnd) return false;
    node.apps = node.apps.filter(function (a) {
      return a.name.toLowerCase() !== key;
    });
    if (node.apps.length === 0) node.isEnd = false;
    return Object.keys(node.children).length === 0 && !node.isEnd;
  }
  var ch = key[depth];
  if (!node.children[ch]) return false;
  var shouldDelete = this._removeHelper(node.children[ch], key, depth + 1);
  if (shouldDelete) {
    delete node.children[ch];
    return Object.keys(node.children).length === 0 && !node.isEnd;
  }
  return false;
};

AppTrie.prototype.clear = function () {
  this.root = new TrieNode();
};

AppTrie.prototype.allApps = function () {
  var results = [];
  this._collect(this.root, results, Infinity);
  return results;
};
