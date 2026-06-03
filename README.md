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
- *Optional:* wired modems + networking cable if you want to place the
  computer somewhere other than directly touching the monitor and the
  RS Bridge

## In-world setup

1. Build the monitor wall (any size; 4×4 is the design target).
2. Wire the RS Bridge into your Refined Storage network — treat it like
   any other RS device; it just needs to be on the same RS network as
   your Crafters.

Then pick how the computer connects to them:

**Direct attach (simplest):**
Place the advanced computer so it touches the RS Bridge block on one
side and one block of the monitor multiblock on another. Run
`peripherals` on the computer's terminal — both should appear by side
name (`top`/`bottom`/`left`/`right`/`front`/`back`). If only one shows
up, slide the computer to a different block of the monitor wall.

**Wired modem network (if you want to place them apart):**
Attach a wired modem to each of: the computer, one block of the monitor
wall, and the RS Bridge. Connect them with networking cable and
**right-click each modem to activate it** (red ring → green ring).
On `peripherals` they'll appear as `monitor_n` and `rsBridge_n`.

Auto-detect handles both cases — no config change is needed when you
switch between them.

## Deploy from GitHub

On the in-game computer's terminal:

```
wget run https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main/install.lua
```

That fetches every file into the current directory and prints a check
of the peripherals it found. When it's done:

- `startup` — launch now in the current session.
- `reboot` — restart the computer; `startup.lua` will run automatically
  on every world load from then on.

If you'd rather pull files by hand, each one is at
`https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main/<filename>`
and can be fetched with `wget <url> <filename>`.

If you edit on the host instead of in-game, copy the `.lua` files into
the computer's save-folder directory at
`<world>/computercraft/computer/<id>/`.

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

Set `monitorName`/`bridgeName` to a specific peripheral string when
auto-detect picks the wrong one (e.g. you have two monitors). Valid
values:

- Direct-attached: a side name — `"top"`, `"bottom"`, `"left"`,
  `"right"`, `"front"`, `"back"`.
- Modem-attached: the modem peripheral name — e.g. `"monitor_2"`,
  `"rsBridge_0"`.

## Adding swatch colours

The default palette covers common vanilla items and uses keyword fallbacks
(`ingot`, `wood`, `dust`, …) for everything else. To pin a specific colour
to a specific item, edit the `palette` table in `swatch.lua` or call
`swatch.register("modid:item_name", colors.cyan)` from `startup.lua` before
the main loop.

## Troubleshooting

- **`No rsBridge peripheral found`** — the computer isn't touching the
  RS Bridge and there's no active modem network linking them, or the
  bridge isn't connected to the RS controller side of your network.
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
