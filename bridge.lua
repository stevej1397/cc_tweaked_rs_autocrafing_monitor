-- Thin wrapper around Advanced Peripherals' rsBridge peripheral.
-- The whole AP API surface is funnelled through here so version drift
-- in AP only forces edits in this one file.

local M = {}

local bridge

local function findByType(typeName)
    for _, n in ipairs(peripheral.getNames()) do
        if peripheral.getType(n) == typeName then return n end
    end
end

function M.attach(name)
    name = name or findByType("rsBridge")
    if not name then
        error("rsBridge peripheral not found - connect one via wired modem")
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
