# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A CC: Tweaked (Minecraft) program written in Lua. It polls a Refined Storage system through the **Advanced Peripherals `rsBridge`** peripheral and renders a two-pane status display on an Advanced Monitor (designed for a 4×4 monitor wall):

- **Left pane** — jobs currently being crafted, with a progress bar.
- **Right pane** — jobs completed in the last hour, aggregated per item.
- **Watchdog** — any active job older than 30 minutes is auto-cancelled.

There is no build, lint, or test step. To "run" it, copy the `.lua` files into a CC: Tweaked computer's filesystem (in-world or via the save folder at `world/computercraft/computer/<id>/`). Naming the entry file `startup.lua` makes it auto-run on world load. There is no host-side toolchain — edits go straight to the game.

## Architecture

Flat module layout, loaded via `require` after `startup.lua` extends `package.path` to the program's directory. One concern per file:

```
startup.lua    main loop: poll -> tick tracker -> watchdog -> render -> save
config.lua     tunables (poll interval, watchdog timeout, history window, peripheral names)
bridge.lua     thin wrapper around the rsBridge peripheral (the only AP-aware file)
tracker.lua    state: active jobs (with start times) + completed ring; persistence
history.lua    folds completions into one entry per item name
watchdog.lua   cancels active jobs older than the timeout
display.lua    monitor rendering (title bar, vertical split, swatches, progress bars)
swatch.lua    item-id -> CC color map for the 2×2 swatches; keyword fallbacks
state.dat      runtime-only; persisted tracker state so a reboot keeps the last hour
```

Data flows one way each tick: `bridge.getTasks() -> normaliseTask() -> tracker.tick() -> {watchdog, history.aggregate} -> display.render()`. The tracker is the single source of truth for what's active and what completed; nothing else holds job state.

## Conventions worth knowing before editing

- **Progress bar = elapsed / watchdog timeout, not actual RS progress.** AP doesn't expose a reliable per-task completion percentage, so the bar's job is to show how close a craft is to being auto-cancelled (green → yellow → red at 50%/80%). If you ever wire in real progress data, change this in `display.lua` and update the colour thresholds.
- **Tasks are fingerprinted as `name#count`** in `tracker.lua` because RS/AP doesn't surface a stable task ID. Two simultaneous identical orders therefore collapse into one tracked job. Don't try to "fix" this with synthetic UUIDs — they won't survive a reboot or a chunk unload because the fingerprint is the only way to re-identify a task across polls.
- **AP API drift is contained in `bridge.lua`.** `cancelCraftingTask`'s signature has varied across AP versions, so the wrapper tries `(name, amount)` then falls back to `(name)`. `normaliseTask` in `startup.lua` is similarly forgiving about task shape. If you upgrade AP and something breaks, those two functions are where to start.
- **Peripheral names default to auto-detect** (`rsBridge`, `monitor`). Set `config.bridgeName` / `config.monitorName` explicitly when there's more than one of either on the wired modem network.
- **Cancelled jobs are NOT logged to history.** The watchdog sets `cancelledAt` on the job; when the next tick sees it disappear from the AP task list, that flag suppresses the completion entry. Preserve this when changing watchdog or tracker logic — otherwise auto-cancels will pollute the "last hour" pane.
- **Times are seconds since epoch via `os.epoch("utc") / 1000`.** Don't mix with `os.clock()` (which is uptime, not wall-clock, and won't survive reboots).
- **`config.debug = true`** prints the first raw task each tick. Use this when AP changes shape and `normaliseTask` needs updating.

## Common edits

- **Add a swatch colour for a frequently-crafted item:** add an entry to `palette` in `swatch.lua`, or call `swatch.register(name, color)` from `startup.lua` before the main loop.
- **Change the watchdog timeout or history window:** edit `config.lua`. Both are in seconds.
- **Tune polling cadence vs. CPU load:** `config.pollInterval`. Below ~1s the AP call becomes the bottleneck and is rude to other users on the same network.
