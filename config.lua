return {
    -- Peripheral names. Leave nil to auto-detect by type.
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
