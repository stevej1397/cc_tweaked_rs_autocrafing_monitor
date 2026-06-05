-- Diagnostic snapshot of rsBridge.getCraftingTasks().
--
-- Run with crafts in flight to write every active task to task_shape.txt.
-- During a big multi-job craft this captures the full shape AP returns
-- under load, including sub-tasks and processing patterns.

local CANDIDATES = { "rsBridge", "rs_bridge", "advancedperipherals:rs_bridge" }
local FUZZY      = "rsbridge"
local OUTPUT     = "task_shape.txt"

local function findBridge()
    for _, n in ipairs(peripheral.getNames()) do
        if peripheral.hasType then
            for _, c in ipairs(CANDIDATES) do
                if peripheral.hasType(n, c) then return n, c end
            end
        end
        local t = peripheral.getType(n) or ""
        for _, c in ipairs(CANDIDATES) do
            if t == c then return n, t end
        end
        if t:lower():find(FUZZY) then return n, t end
    end
end

local name, ptype = findBridge()
if not name then
    printError("No RS Bridge peripheral found")
    return
end
print(("RS Bridge: %s (%s)"):format(name, ptype))

local bridge = peripheral.wrap(name)
local tasks = bridge.getCraftingTasks() or {}
local n = #tasks
print(("Active tasks: %d"):format(n))
if n == 0 then
    print("No active crafts. Queue something first and re-run 'inspect'.")
    return
end

local f = fs.open(OUTPUT, "w")
if not f then
    printError("Could not open " .. OUTPUT .. " for writing")
    return
end

f.write(("-- Snapshot of rsBridge.getCraftingTasks()\n"))
f.write(("-- Captured at epoch %d ms\n"):format(os.epoch("utc")))
f.write(("-- Active tasks: %d\n\n"):format(n))
for i, task in ipairs(tasks) do
    f.write(("-- task[%d] --\n"):format(i))
    f.write(textutils.serialize(task))
    f.write("\n\n")
end
f.close()

print(("Wrote %d tasks to %s"):format(n, OUTPUT))
print()
print("Preview of first task:")
print(textutils.serialize(tasks[1]))

print()
print("Cancel-related methods on this bridge:")
local found = false
for _, method in ipairs(peripheral.getMethods(name)) do
    if method:lower():find("cancel") or method:lower():find("craft") then
        print("  " .. method)
        found = true
    end
end
if not found then
    print("  (none found)")
end
