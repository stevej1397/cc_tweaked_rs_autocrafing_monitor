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
swatch.lua     item-id -> CC color map for the 2×2 swatches; keyword fallbacks
install.lua    wget-run installer; fetches all files from GitHub and checks peripherals
inspect.lua    diagnostic tool; dumps all active rsBridge tasks to task_shape.txt
state.dat      runtime-only; persisted tracker state so a reboot keeps the last hour
```

Data flows one way each tick: `bridge.getTasks() -> normaliseTask() -> tracker.tick() -> {watchdog, history.aggregate} -> display.render()`. The tracker is the single source of truth for what's active and what completed; nothing else holds job state.

## Conventions worth knowing before editing

- **Progress bar has two modes**, selected per-task in `display.lua`:
  - When `job.progress` is set (from `raw.completion` in `findProgress`), the bar fills solid lime with that fraction and the count line shows a percentage.
  - When it isn't, the bar falls back to elapsed/watchdog with a green→yellow→red gradient (50%/80% thresholds), doubling as the auto-cancel warning.
  In practice most tasks land in the fallback mode: AP's `completion` field stays at `0` for most of a craft on the version observed here. `raw.crafted` is NOT a usable progress signal — it's "items still needing to be crafted" (or `-1` when not yet computed), so don't reach for `crafted/quantity` as a fallback.
- **Tasks are fingerprinted by `raw.id` (the RS task UUID) when present**, with `name#count` as a fallback when an id isn't available. UUIDs let concurrent identical orders track as separate jobs. Persisted state from before this change uses the old fingerprint format — clear `state.dat` after upgrading.
- **Item names are validated with `isItemId`** in `startup.lua`: only strings containing `:` are accepted (e.g. `minecraft:diamond`). This prevents RS task UUIDs (which are bare hex strings) from being mistaken for item names. Any new name-extraction path in `findName` must go through this gate.
- **Unknown task shapes are dumped to `unknown_task.txt`** (once per session) when `findName` can't extract an item id. Check this file when AP updates break name detection — it has the raw serialised task.
- **AP API drift is contained in `bridge.lua`.** `cancelCraftingTask`'s signature has varied across AP versions, so the wrapper tries `(name, amount)` then falls back to `(name)`. `normaliseTask` in `startup.lua` is similarly forgiving about task shape. If you upgrade AP and something breaks, those two functions are where to start.
- **`inspect.lua` is a standalone diagnostic script** — run it in-game with active crafts to dump every task's full shape to `task_shape.txt`. Useful when AP changes and you need to see what fields are actually present.
- **Peripheral names default to auto-detect** (`rsBridge`, `monitor`). Set `config.bridgeName` / `config.monitorName` explicitly when there's more than one of either on the wired modem network.
- **Cancelled jobs are NOT logged to history.** The watchdog sets `cancelledAt` on the job; when the next tick sees it disappear from the AP task list, that flag suppresses the completion entry. Preserve this when changing watchdog or tracker logic — otherwise auto-cancels will pollute the "last hour" pane.
- **Times are seconds since epoch via `os.epoch("utc") / 1000`.** Don't mix with `os.clock()` (which is uptime, not wall-clock, and won't survive reboots).
- **`config.debug = true`** prints the first raw task each tick. Use this when AP changes shape and `normaliseTask` needs updating.

## Common edits

- **Add a swatch colour for a frequently-crafted item:** add an entry to `palette` in `swatch.lua`, or call `swatch.register(name, color)` from `startup.lua` before the main loop.
- **Change the watchdog timeout or history window:** edit `config.lua`. Both are in seconds.
- **Tune polling cadence vs. CPU load:** `config.pollInterval`. Below ~1s the AP call becomes the bottleneck and is rude to other users on the same network.
