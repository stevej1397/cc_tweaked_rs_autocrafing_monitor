-- Refined Storage crafting monitor for CC: Tweaked + Advanced Peripherals.
-- Place this on a computer wired (via a wired modem network) to:
--   * an Advanced Monitor (any size; designed for ~4x4)
--   * an Advanced Peripherals RS Bridge
-- Saving the file as `startup.lua` makes it run on world load.

local programDir = fs.getDir(shell.getRunningProgram())
package.path = programDir .. "/?.lua;" .. package.path

local config   = require("config")
local bridge   = require("bridge")
local tracker  = require("tracker")
local history  = require("history")
local watchdog = require("watchdog")
local display  = require("display")
local swatch   = require("swatch")

local function findPeripheral(typeName)
    for _, n in ipairs(peripheral.getNames()) do
        if peripheral.getType(n) == typeName then return n end
    end
end

-- Pulls (name, count) out of whatever shape AP returns. Defensive
-- because AP's task shape has shifted across versions; we walk every
-- field where the item id has been seen to live. When everything fails,
-- the raw task is dumped to UNKNOWN_DUMP (once per session) so the
-- actual structure can be inspected.

local UNKNOWN_DUMP = "unknown_task.txt"
local dumpedUnknown = false

-- Real Minecraft item ids always look like "modid:item_name". RS uses
-- UUID-shaped strings for task identifiers and we never want those, so
-- gate every candidate on the colon.
local function isItemId(s)
    return type(s) == "string" and s:find(":") ~= nil
end

local function findName(raw)
    if type(raw) ~= "table" then return nil end
    if isItemId(raw.name) then return raw.name end
    -- AP wraps the item in `resource` on at least some versions.
    if type(raw.resource) == "table" then
        if isItemId(raw.resource.name) then return raw.resource.name end
        if isItemId(raw.resource.id)   then return raw.resource.id end
    end
    if type(raw.item) == "table" then
        if isItemId(raw.item.name) then return raw.item.name end
        if isItemId(raw.item.id)   then return raw.item.id end
    end
    if isItemId(raw.output) then return raw.output end
    if type(raw.output) == "table" then
        if isItemId(raw.output.name) then return raw.output.name end
        local first = raw.output[1]
        if isItemId(first) then return first end
        if type(first) == "table" and isItemId(first.name) then return first.name end
    end
    if type(raw.outputs) == "table" then
        for _, o in ipairs(raw.outputs) do
            if isItemId(o) then return o end
            if type(o) == "table" and isItemId(o.name) then return o.name end
        end
    end
    if type(raw.pattern) == "table" then
        local p = raw.pattern
        if type(p.outputs) == "table" then
            for _, o in ipairs(p.outputs) do
                if isItemId(o) then return o end
                if type(o) == "table" and isItemId(o.name) then return o.name end
            end
        end
        if isItemId(p.output) then return p.output end
        if type(p.output) == "table" and isItemId(p.output.name) then
            return p.output.name
        end
    end
    return nil
end

local function findCount(raw)
    if type(raw) ~= "table" then return 1 end
    return raw.quantity or raw.count or raw.amount or raw.size or 1
end

local function dumpRaw(raw)
    if dumpedUnknown then return end
    local f = fs.open(UNKNOWN_DUMP, "w")
    if not f then return end
    f.write("-- Raw AP task with no extractable item name.\n")
    f.write("-- Paste contents to the maintainer.\n\n")
    f.write(textutils.serialize(raw))
    f.close()
    dumpedUnknown = true
    print("[debug] wrote unknown task shape to " .. UNKNOWN_DUMP)
end

local function normaliseTask(raw)
    local name = findName(raw)
    if not name then dumpRaw(raw) end
    return { name = name or "?", count = findCount(raw) }
end

local function now() return os.epoch("utc") / 1000 end

bridge.attach(config.bridgeName)

local monName = config.monitorName or findPeripheral("monitor")
if not monName then error("No monitor peripheral found") end
local mon = peripheral.wrap(monName)
mon.setTextScale(config.textScale)

tracker.load(config.stateFile)

local lastSave = now()

while true do
    local t = now()

    local ok, rawTasks = pcall(bridge.getTasks)
    if not ok then
        print("[bridge] poll failed: " .. tostring(rawTasks))
        rawTasks = {}
    end
    if config.debug and rawTasks[1] then
        print(textutils.serialize(rawTasks[1]))
    end

    tracker.tick(t, rawTasks, normaliseTask)

    watchdog.run(t, tracker.activeJobs(), config.watchdogSeconds, bridge.cancel,
        function(job, success, err)
            print(("[watchdog] cancel %s x%d : %s")
                :format(job.name, job.count, success and "ok" or tostring(err)))
        end)

    local active     = tracker.activeJobs()
    local completed  = tracker.recentCompletions(t, config.historyWindowSeconds)
    local aggregated = history.aggregate(completed)

    local okR, errR = pcall(display.render, mon, t, active, aggregated, config, swatch)
    if not okR then print("[display] " .. tostring(errR)) end

    if t - lastSave > config.saveInterval then
        tracker.save(config.stateFile)
        lastSave = t
    end

    sleep(config.pollInterval)
end
