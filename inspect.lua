-- One-shot diagnostic. Run this with an RS craft actively in progress
-- to dump the raw shape AP returns from getCraftingTasks(). Writes the
-- first task to task_shape.txt and prints it to the terminal.

local CANDIDATES = { "rsBridge", "rs_bridge", "advancedperipherals:rs_bridge" }
local FUZZY      = "rsbridge"

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
print(("Active tasks: %d"):format(#tasks))
if #tasks == 0 then
    print("No active crafts. Queue one from your RS terminal,")
    print("then re-run 'inspect'.")
    return
end

local payload = textutils.serialize(tasks[1])

local f = fs.open("task_shape.txt", "w")
if f then
    f.write("-- First active task from rsBridge.getCraftingTasks()\n")
    f.write("-- Paste contents to the project maintainer.\n\n")
    f.write(payload)
    f.close()
    print("Wrote task_shape.txt")
end

print()
print("---- task[1] ----")
print(payload)
