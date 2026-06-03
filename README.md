# RS Autocrafting Monitor

A CC: Tweaked (Lua) program that watches a Refined Storage system through the
**Advanced Peripherals `rsBridge`** peripheral and renders a two-pane status
board on an Advanced Monitor:

- **Left pane** — jobs currently being crafted, with a colour-coded progress
  bar (green → yellow → red as the job ages).
- **Right pane** — jobs completed in the last hour, aggregated per item.
- **Watchdog** — any active job older than 30 minutes is automatically
  cancelled. Cancelled jobs are not logged to the history pane.

Each item is shown with a 2×2 colour swatch next to its name. CC: Tweaked
can't render real Minecraft item textures, so swatch colours come from
`swatch.lua`; extend the palette there for items you craft often.

## Requirements

- Minecraft with **CC: Tweaked** and **Advanced Peripherals**
- **Refined Storage** with at least one Crafter / autocrafting set up
- One **Advanced Computer**
- One **Advanced Monitor** (designed for a 4×4 wall, but any size works)
- An **RS Bridge** block (from Advanced Peripherals)
- **Wired modems** + networking cable to tie the computer to the monitor and
  the RS Bridge

## In-world setup

1. Build the 4×4 advanced monitor wall.
2. Place the advanced computer somewhere convenient.
3. Place the RS Bridge block adjacent to your Refined Storage network
   (treat it like any other RS device — it needs to be on the same RS
   network as your Crafters).
4. Attach a wired modem to each of: the computer, one monitor block, and
   the RS Bridge. Connect them with networking cable and **right-click each
   modem to activate it** (red ring → green ring).

When the computer boots you should see `monitor_n` and `rsBridge_n` listed
by `peripherals` on its terminal. If not, the modems aren't activated or
aren't on the same network.

## Deploy from GitHub

On the in-game computer's terminal:

```
wget run https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main/install.lua
```

…or, since this repo doesn't ship an installer, pull each file by hand:

```
set REPO https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main
wget %REPO%/startup.lua  startup.lua
wget %REPO%/config.lua   config.lua
wget %REPO%/bridge.lua   bridge.lua
wget %REPO%/tracker.lua  tracker.lua
wget %REPO%/history.lua  history.lua
wget %REPO%/watchdog.lua watchdog.lua
wget %REPO%/display.lua  display.lua
wget %REPO%/swatch.lua   swatch.lua
reboot
```

(In CC: Tweaked the shell uses `$VAR`-style variables differently than the
host shell; the simplest path is to type each `wget` line in full. The
list above just shows what you're fetching.)

Alternatively, if you edit on the host: copy all the `.lua` files into the
computer's save-folder directory, which lives at:

```
<world>/computercraft/computer/<id>/
```

Running this as `startup.lua` makes it launch on every world load.

## Configuration

Edit `config.lua`. All times are in seconds.

| Key                    | Default | Meaning                                                |
| ---------------------- | ------- | ------------------------------------------------------ |
| `monitorName`          | `nil`   | Auto-detect first peripheral of type `monitor`         |
| `bridgeName`           | `nil`   | Auto-detect first peripheral of type `rsBridge`        |
| `pollInterval`         | `2`     | Seconds between RS polls                               |
| `watchdogSeconds`      | `1800`  | Auto-cancel after this many seconds                    |
| `historyWindowSeconds` | `3600`  | How long completed jobs stay on the right pane         |
| `saveInterval`         | `30`    | Persist tracker state every N seconds                  |
| `textScale`            | `0.5`   | Monitor text scale (smaller = more text, lower res)    |
| `debug`                | `false` | Prints the first raw AP task each tick (useful if names show as `?`) |

Set `monitorName`/`bridgeName` to a specific peripheral string when you
have multiple of either on the same modem network.

## Adding swatch colours

The default palette covers common vanilla items and uses keyword fallbacks
(`ingot`, `wood`, `dust`, …) for everything else. To pin a specific colour
to a specific item, edit the `palette` table in `swatch.lua` or call
`swatch.register("modid:item_name", colors.cyan)` from `startup.lua` before
the main loop.

## Troubleshooting

- **`No rsBridge peripheral found`** — modems aren't activated, the RS
  Bridge isn't on the same modem network, or it isn't connected to the RS
  controller side.
- **Item names show as `?`** — Advanced Peripherals changed its task
  shape. Set `debug = true` in `config.lua`, reboot, and look at the
  printed table; adjust `normaliseTask` in `startup.lua` to read the
  fields you actually see.
- **Watchdog logs `cancel … : false`** — your AP version uses a different
  `cancelCraftingTask` signature than the two `bridge.lua` already tries.
  Add the right call to `bridge.cancel`.
- **History wipes on world reload** — make sure `state.dat` is being
  written; the computer needs write access to its own filesystem (it does
  by default).

## File layout

| File           | Role                                                             |
| -------------- | ---------------------------------------------------------------- |
| `startup.lua`  | Main loop; auto-runs on boot                                     |
| `config.lua`   | Tunables                                                         |
| `bridge.lua`   | The only file that knows about the Advanced Peripherals API      |
| `tracker.lua`  | Active job state + completion ring + persistence to `state.dat`  |
| `history.lua`  | Aggregates completed jobs by item name                           |
| `watchdog.lua` | Cancels jobs older than `watchdogSeconds`                        |
| `display.lua`  | Monitor renderer (title, vertical split, swatches, progress bars)|
| `swatch.lua`   | Item-name → CC colour palette for the swatches                   |
| `CLAUDE.md`    | Internal notes for AI assistants editing this repo               |
