-- Owns the state of active and recently-completed crafting jobs.
--
-- Tasks are fingerprinted by the RS task UUID (raw.id) when available;
-- two concurrent identical orders track separately because their UUIDs
-- differ. Falls back to "name#count" if a task lacks an id (older AP
-- versions or unusual task shapes); in that case identical concurrent
-- orders collapse into one tracked job - acceptable for monitor use.

local M = {}

local active    = {}  -- fp -> { name, count, startedAt, lastSeen, progress, cancelledAt? }
local completed = {}  -- list of { name, count, completedAt }

local function fp(t)
    if t.id then return "id:" .. t.id end
    return "nc:" .. (t.name or "?") .. "#" .. tostring(t.count or 0)
end

function M.tick(now, rawTasks, normalise)
    local seen = {}
    for _, raw in ipairs(rawTasks) do
        local t = normalise(raw)
        local key = fp(t)
        seen[key] = true
        if not active[key] then
            active[key] = {
                name      = t.name,
                count     = t.count,
                startedAt = now,
                lastSeen  = now,
                progress  = t.progress,
            }
        else
            active[key].lastSeen = now
            active[key].progress = t.progress
        end
    end
    for key, job in pairs(active) do
        if not seen[key] then
            if not job.cancelledAt then
                completed[#completed + 1] = {
                    name        = job.name,
                    count       = job.count,
                    completedAt = now,
                }
            end
            active[key] = nil
        end
    end
end

function M.activeJobs() return active end

function M.recentCompletions(now, windowSeconds)
    local cutoff = now - windowSeconds
    local kept = {}
    for _, c in ipairs(completed) do
        if c.completedAt >= cutoff then kept[#kept + 1] = c end
    end
    completed = kept
    return completed
end

function M.save(path)
    local f = fs.open(path, "w")
    if not f then return end
    f.write(textutils.serialize({ active = active, completed = completed }))
    f.close()
end

function M.load(path)
    if not fs.exists(path) then return end
    local f = fs.open(path, "r")
    if not f then return end
    local data = textutils.unserialize(f.readAll())
    f.close()
    if type(data) == "table" then
        active    = data.active    or {}
        completed = data.completed or {}
    end
end

return M
