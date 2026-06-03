-- Renders the monitor frame.
--
-- Layout: title row across the top, then a vertical split.
--   Left pane  = active jobs   (swatch + name, count + elapsed, progress bar)
--   Right pane = recent crafts (swatch + name, aggregated count + age)
--
-- Progress bar fills with real RS completion (from raw.completion or
-- crafted/quantity in startup.lua's normaliseTask). The watchdog warning
-- is shown separately by turning the job's name red once elapsed time
-- crosses 80% of the auto-cancel threshold.

local M = {}

local function setColors(mon, fg, bg)
    if fg then mon.setTextColor(fg) end
    if bg then mon.setBackgroundColor(bg) end
end

local function writeAt(mon, x, y, text, fg, bg)
    setColors(mon, fg, bg)
    mon.setCursorPos(x, y)
    mon.write(text)
end

local function fillLine(mon, x, y, width, bg)
    setColors(mon, nil, bg)
    mon.setCursorPos(x, y)
    mon.write(string.rep(" ", width))
end

local function drawSwatch(mon, x, y, color)
    setColors(mon, nil, color)
    mon.setCursorPos(x, y);     mon.write("  ")
    mon.setCursorPos(x, y + 1); mon.write("  ")
end

local function drawProgressBar(mon, x, y, width, fraction)
    fraction = math.max(0, math.min(1, fraction))
    setColors(mon, nil, colors.gray)
    mon.setCursorPos(x, y)
    mon.write(string.rep(" ", width))
    local fill = math.floor(width * fraction + 0.5)
    if fill > 0 then
        setColors(mon, nil, colors.lime)
        mon.setCursorPos(x, y)
        mon.write(string.rep(" ", fill))
    end
end

local function prettyName(full)
    if not full or full == "" then return "?" end
    local colon = full:find(":")
    local name = colon and full:sub(colon + 1) or full
    name = name:gsub("_", " ")
    return (name:gsub("(%a)(%w*)", function(a, b) return a:upper() .. b:lower() end))
end

local function truncate(s, max)
    if #s <= max then return s end
    if max <= 1 then return s:sub(1, max) end
    return s:sub(1, max - 1) .. "."
end

local function fmtDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    if seconds < 60 then return seconds .. "s" end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m < 60 then return string.format("%dm%02ds", m, s) end
    local h = math.floor(m / 60)
    m = m % 60
    return string.format("%dh%02dm", h, m)
end

local function drawHeader(mon, x, y, width, text, bg)
    fillLine(mon, x, y, width, bg)
    writeAt(mon, x, y, " " .. text, colors.white, bg)
end

local function sortedActive(active)
    local list = {}
    for _, job in pairs(active) do list[#list + 1] = job end
    table.sort(list, function(a, b) return a.startedAt < b.startedAt end)
    return list
end

local function renderActivePane(mon, x0, width, y0, height, list, now, watchdogSec, swatch)
    drawHeader(mon, x0, y0, width, "CRAFTING NOW", colors.blue)
    local rowsPer = 3
    local maxEntries = math.floor((height - 1) / rowsPer)
    for i = 1, math.min(maxEntries, #list) do
        local job = list[i]
        local y = y0 + 1 + (i - 1) * rowsPer
        drawSwatch(mon, x0, y, swatch.forItem(job.name))
        local elapsed = now - job.startedAt
        local elapsedFrac = elapsed / watchdogSec
        local progress = job.progress or 0
        local nameColor = (elapsedFrac > 0.8) and colors.red or colors.white
        local pctStr = job.progress
            and string.format("%d%%", math.floor(progress * 100 + 0.5))
            or "--"
        local textX, textW = x0 + 3, width - 3
        writeAt(mon, textX, y, truncate(prettyName(job.name), textW),
                nameColor, colors.black)
        writeAt(mon, textX, y + 1,
                truncate(("x%d  %s  %s"):format(job.count, fmtDuration(elapsed), pctStr), textW),
                colors.lightGray, colors.black)
        drawProgressBar(mon, x0, y + 2, width, progress)
        setColors(mon, colors.white, colors.black)
    end
    if #list == 0 then
        writeAt(mon, x0 + 1, y0 + 2, "(idle)", colors.gray, colors.black)
    elseif #list > maxEntries then
        writeAt(mon, x0, y0 + height - 1,
                ("+%d more"):format(#list - maxEntries),
                colors.gray, colors.black)
    end
end

local function renderHistoryPane(mon, x0, width, y0, height, agg, now, swatch)
    drawHeader(mon, x0, y0, width, "LAST HOUR", colors.green)
    local rowsPer = 3
    local maxEntries = math.floor((height - 1) / rowsPer)
    for i = 1, math.min(maxEntries, #agg) do
        local e = agg[i]
        local y = y0 + 1 + (i - 1) * rowsPer
        drawSwatch(mon, x0, y, swatch.forItem(e.name))
        local textX, textW = x0 + 3, width - 3
        local countStr = "x" .. tostring(e.count)
        if e.jobs > 1 then countStr = countStr .. " (" .. e.jobs .. " jobs)" end
        writeAt(mon, textX, y,     truncate(prettyName(e.name), textW),
                colors.white, colors.black)
        writeAt(mon, textX, y + 1, truncate(countStr, textW),
                colors.lightGray, colors.black)
        writeAt(mon, x0, y + 2,
                truncate(fmtDuration(now - e.latestAt) .. " ago", width),
                colors.gray, colors.black)
    end
    if #agg == 0 then
        writeAt(mon, x0 + 1, y0 + 2, "(no recent crafts)", colors.gray, colors.black)
    elseif #agg > maxEntries then
        writeAt(mon, x0, y0 + height - 1,
                ("+%d more"):format(#agg - maxEntries),
                colors.gray, colors.black)
    end
end

function M.render(mon, now, active, aggregated, config, swatch)
    setColors(mon, colors.white, colors.black)
    mon.clear()
    local w, h = mon.getSize()
    fillLine(mon, 1, 1, w, colors.gray)
    writeAt(mon, 1, 1, " RS Crafting Monitor", colors.white, colors.gray)
    local divider = math.floor(w / 2)
    setColors(mon, nil, colors.gray)
    for y = 2, h do
        mon.setCursorPos(divider, y); mon.write(" ")
    end
    local leftX,  leftW  = 1,           divider - 1
    local rightX, rightW = divider + 1, w - divider
    local paneY, paneH = 2, h - 1
    renderActivePane(mon, leftX, leftW, paneY, paneH,
                     sortedActive(active), now, config.watchdogSeconds, swatch)
    renderHistoryPane(mon, rightX, rightW, paneY, paneH,
                      aggregated, now, swatch)
    setColors(mon, colors.white, colors.black)
end

return M
