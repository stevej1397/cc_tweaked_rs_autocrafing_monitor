-- Thin wrapper around Advanced Peripherals' rsBridge peripheral.
-- The whole AP API surface is funnelled through here so version drift
-- in AP only forces edits in this one file.

local M = {}

local bridge

-- AP has spelled this peripheral several ways across versions; we accept
-- any of these and also fall back to a fuzzy "rsbridge" match (which
-- still won't collide with e.g. meBridge for AE2).
local BRIDGE_TYPES = {
    "rsBridge",
    "rs_bridge",
    "advancedperipherals:rs_bridge",
}
local BRIDGE_FUZZY = "rsbridge"

local function matchesAny(name, candidates, fuzzy)
    if peripheral.hasType then
        for _, c in ipairs(candidates) do
            if peripheral.hasType(name, c) then return c end
        end
    end
    local t = peripheral.getType(name)
    if not t then return nil end
    for _, c in ipairs(candidates) do
        if t == c then return t end
    end
    if fuzzy and t:lower():find(fuzzy) then return t end
end

local function findPeripheral(candidates, fuzzy)
    for _, n in ipairs(peripheral.getNames()) do
        local t = matchesAny(n, candidates, fuzzy)
        if t then return n end
    end
end

function M.attach(name)
    name = name or findPeripheral(BRIDGE_TYPES, BRIDGE_FUZZY)
    if not name then
        error("RS Bridge peripheral not found - attach it directly to the computer or via a wired modem")
    end
    bridge = peripheral.wrap(name)
    if not bridge then error("Failed to wrap peripheral: " .. name) end
    return name
end

function M.getTasks()
    return bridge.getCraftingTasks() or {}
end

-- AP's cancel signature varies. Try (name, amount), fall back to (name).
function M.cancel(itemName, amount)
    local ok, err = pcall(bridge.cancelCraftingTask, itemName, amount)
    if not ok then
        ok, err = pcall(bridge.cancelCraftingTask, itemName)
    end
    return ok, err
end

return M
