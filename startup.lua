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

-- Pulls (name, count) out of whatever shape AP returns. Defensive because
-- AP's task shape has shifted across versions; we accept several common
-- spellings so the rest of the program doesn't have to care.
local function normaliseTask(raw)
    local name, count = "?", 1
    if type(raw) ~= "table" then return { name = name, count = count } end
    if raw.pattern and raw.pattern.outputs and raw.pattern.outputs[1] then
        name = raw.pattern.outputs[1].name or name
    elseif raw.name then
        name = raw.name
    elseif raw.item and raw.item.name then
        name = raw.item.name
    end
    count = raw.quantity or raw.count or raw.amount or count
    return { name = name, count = count }
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
