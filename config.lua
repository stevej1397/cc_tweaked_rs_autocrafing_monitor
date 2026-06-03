return {
    -- Peripheral names. Leave nil to auto-detect by type (works for
    -- both direct-attached and modem-attached peripherals).
    -- Direct-attached: use a side name -- "top", "bottom", "left",
    --     "right", "front", "back".
    -- Modem-attached:  use the modem name -- e.g. "monitor_0", "rsBridge_0".
    monitorName = nil,
    bridgeName  = nil,

    pollInterval         = 2,          -- seconds between RS polls
    watchdogSeconds      = 30 * 60,    -- cancel any task older than this
    historyWindowSeconds = 60 * 60,    -- how long completed jobs stay on the right pane
    saveInterval         = 30,         -- persist state every N seconds

    stateFile = "state.dat",
    textScale = 0.5,
    debug     = false,                 -- prints the first raw task each tick
}
