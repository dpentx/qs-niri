// "18:30" (today, or tomorrow when already past), "+45" (minutes from now), "2026-11-02 09:00".
// Returns epoch ms, or 0 when the text is not understood.
function parseWhen(str, now) {
    str = (str || "").trim()
    let m
    if ((m = /^\+(\d{1,4})$/.exec(str))) return now + Number(m[1]) * 60000
    if ((m = /^(\d{1,2}):(\d{2})$/.exec(str))) {
        const d = new Date(now)
        d.setHours(Number(m[1]), Number(m[2]), 0, 0)
        if (Number(m[1]) > 23 || Number(m[2]) > 59) return 0
        return d.getTime() <= now ? d.getTime() + 86400000 : d.getTime()
    }
    if ((m = /^(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})$/.exec(str))) {
        const t = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5])).getTime()
        return t > now ? t : 0
    }
    return 0
}
if (typeof module !== "undefined") module.exports = { parseWhen }
