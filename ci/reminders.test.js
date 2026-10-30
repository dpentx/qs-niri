// node ci/reminders.test.js
const assert = require("assert"), { parseWhen } = require("../services/reminders.js")
const now = new Date(2026, 9, 30, 12, 0).getTime()
assert.strictEqual(parseWhen("+30", now), now + 30 * 60000)
assert.strictEqual(parseWhen("18:30", now), new Date(2026, 9, 30, 18, 30).getTime())
assert.strictEqual(parseWhen("09:00", now), new Date(2026, 9, 31, 9, 0).getTime())   // already past: tomorrow
assert.strictEqual(parseWhen("2026-11-02 09:00", now), new Date(2026, 10, 2, 9, 0).getTime())
assert.strictEqual(parseWhen("25:00", now), 0)
assert.strictEqual(parseWhen("soon", now), 0)
assert.strictEqual(parseWhen("2020-01-01 09:00", now), 0)
console.log("ok")
