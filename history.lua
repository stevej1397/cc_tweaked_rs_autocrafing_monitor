-- Folds the completion list into one entry per item name, summing counts
-- and remembering the most recent completion time. Sorted by display name.

local M = {}

local function displayName(full)
    if not full or full == "" then return "?" end
    local colon = full:find(":")
    local name = colon and full:sub(colon + 1) or full
    name = name:gsub("_", " ")
    return (name:gsub("(%a)(%w*)", function(a, b) return a:upper() .. b:lower() end))
end

function M.aggregate(completions)
    local byName, order = {}, {}
    for _, c in ipairs(completions) do
        local e = byName[c.name]
        if not e then
            e = { name = c.name, count = 0, latestAt = 0, jobs = 0 }
            byName[c.name] = e
            order[#order + 1] = e
        end
        e.count = e.count + c.count
        e.jobs  = e.jobs + 1
        if c.completedAt > e.latestAt then e.latestAt = c.completedAt end
    end
    table.sort(order, function(a, b)
        return displayName(a.name) < displayName(b.name)
    end)
    return order
end

return M
