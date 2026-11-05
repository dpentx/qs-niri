// Key bindings out of a niri config.kdl: the entries of the top-level `binds { ... }` block.
// -> [{ key: "Mod+D", title: "hotkey-overlay-title or empty", action: "spawn touch /tmp/qs-launcher" }]
// shortcut: no `include` files and no multi-line strings; entries disabled with `/-` are skipped.
function parseBinds(text) {
    // blank out comments and strings' braces so depth counting is safe
    let out = [], i = 0, n = text.length
    const m = /(^|\n)\s*binds\s*\{/.exec(text)
    if (!m) return out
    i = m.index + m[0].length
    let depth = 1, start = i, entry = ""
    const entries = []
    let inStr = false, cur = ""
    for (; i < n && depth > 0; i++) {
        const c = text[i]
        if (inStr) { cur += c; if (c === "\\") { cur += text[++i] ?? "" } else if (c === '"') inStr = false; continue }
        if (c === "/" && text[i + 1] === "/") { while (i < n && text[i] !== "\n") i++; cur += "\n"; continue }
        if (c === '"') { inStr = true; cur += c; continue }
        if (c === "{") { depth++; if (depth === 2) { entry = cur.trim(); cur = ""; continue } }
        if (c === "}") { depth--; if (depth === 1) { entries.push({ head: entry, body: cur.trim() }); cur = ""; continue } if (depth === 0) break }
        cur += c
    }
    for (const e of entries) {
        if (e.head.startsWith("/-")) continue
        const t = /^(\S+)((?:\s+[\w-]+=(?:"[^"]*"|\S+))*)\s*$/.exec(e.head)
        if (!t) continue
        const title = /hotkey-overlay-title="([^"]*)"/.exec(t[2] ?? "")
        const action = e.body.replace(/;\s*/g, " ").replace(/"/g, "").replace(/\s+/g, " ").trim()
        out.push({ key: t[1], title: title ? title[1] : "", action })
    }
    return out
}

if (typeof module !== "undefined") {
    module.exports = { parseBinds }
    const assert = require("assert")
    const r = parseBinds(`input { x }
binds {
    // comment { not a block }
    Mod+D hotkey-overlay-title="Launcher" { spawn "touch" "/tmp/qs-launcher"; }
    Mod+Shift+E { quit; }
    /-Mod+X { close-window; }
    Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
}
layout { y }`)
    assert.deepStrictEqual(r.map(x => x.key), ["Mod+D", "Mod+Shift+E", "Mod+WheelScrollDown"])
    assert.strictEqual(r[0].title, "Launcher")
    assert.strictEqual(r[0].action, "spawn touch /tmp/qs-launcher")
    assert.strictEqual(r[1].action, "quit")
    console.log("binds.js ok")
}
