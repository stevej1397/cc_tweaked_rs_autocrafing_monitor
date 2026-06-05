-- Cancels any active job that has been running longer than `timeoutSec`.
-- Marks the job with `cancelledAt` so the tracker won't re-cancel on the
-- next tick (RS takes a poll cycle or two to drop a cancelled task) and
-- so it won't be logged as a normal completion when it disappears.
-- Failed cancels are retried every RETRY_INTERVAL seconds.

local M = {}

local RETRY_INTERVAL = 60

function M.run(now, active, timeoutSec, cancelFn, onAttempt)
    for _, job in pairs(active) do
        if not job.cancelledAt and (now - job.startedAt) > timeoutSec then
            if not job.cancelRetryAt or now >= job.cancelRetryAt then
                local ok, err = cancelFn(job.name, job.count)
                if ok then
                    job.cancelledAt = now
                else
                    job.cancelRetryAt = now + RETRY_INTERVAL
                end
                if onAttempt then onAttempt(job, ok, err) end
            end
        end
    end
end

return M
