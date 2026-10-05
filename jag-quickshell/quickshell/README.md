# quickshell shell for bspwm

The full desktop shell: bar, popups, wallpaper-driven theming, and the
network app. bspwm needs **no patch** — `bspc subscribe report` streams
every desktop/layout change, and actions go straight through `bspc`.
Note bspwm ignores dock struts: the bar's space is reserved via monitor
`top_padding`, which `Bar.qml` syncs per monitor on startup and whenever
the bar height changes (that sync is also what re-tiles windows live
while dragging the height/scale sliders).

Launch: `qs -p ~/.config/jag-quickshell/quickshell` (bspwmrc does this), or
`scripts/bar restart|log` which handles the `-p` flag.

## Portability contract (read before porting to another WM)

This tree is the **reference implementation** for a shell that is vendored
per WM project (openbox next). Cohesion across projects comes from keeping
the shared files byte-identical — `diff -r` between two projects' quickshell
dirs should show only the files listed as WM-specific.

**Shared verbatim (do not fork per WM):**
`Theme.qml` `BarModule.qml` `Popout.qml` `WallpaperPicker.qml`
`Weather.qml` `NotifyPopup.qml` `Network.qml` `CalendarPopup.qml`
`Clock.qml` `Media.qml` `Metrics.qml` `Volume.qml` `Tray.qml` `Bell.qml`
`CapsLock.qml` `Screenshot.qml` `PowerButton.qml` `Launcher.qml` `Title.qml`
`Sys.qml` `TweakSlider.qml` — plus `scripts/wallpaper-theme` (all but its WM tail),
`scripts/network`, `scripts/bar`, and the `quickshell-network/` app.

**WM-specific (rewrite per WM):**
- `Wm.qml` — bspwm backend (`bspc subscribe report`). For EWMH WMs
  (openbox etc.) replace with an `xprop -spy`-based backend
  (`_NET_CURRENT_DESKTOP`, `_NET_NUMBER_OF_DESKTOPS`, client list).
  Titles already come from EWMH xprop and port unchanged.
- `Tags.qml` — driven by Wm's seltags/occtags/urgtags bitmasks; keep the
  visuals, feed from the new backend.
- `LayoutButton.qml` `LayoutPicker.qml` `LayoutIcon.qml` + `scripts/layout`
  — bspwm-only (scripts/layout engine); drop for floating WMs.
- Tail of `scripts/wallpaper-theme` — bspwm: colors.sh borders + bspwmrc
  persistence + `bspc wm -r`. Other WMs: generate their theme file
  (openbox: themerc) + their reload command.

**Interfaces that must never drift between projects:**
- `polybar/colors.ini` palette keys (background, background-alt, foreground,
  primary, secondary, alert, disabled, border) — Theme.qml's watch target.
- `wallpaper-theme <image> <8 semantic> <16 ansi>` argument order.
- IPC targets: `wallpapers` (toggle/random/set), `tweaks` (toggle),
  `wm` (refreshLayout, bspwm only).
- Script names in `scripts/`: wallpaper-theme, network, bar, layout.
- Bar-tweaks state file names: `bar-height` and `bar-scale` in the WM
  config dir (Theme.qml's watch targets, plain integers/floats).

## Live theming

`Theme.qml` watches `polybar/colors.ini`, which `scripts/wallpaper-theme`
rewrites on every wallpaper pick — the bar re-colors in place, no restart.
The picker extracts the palette in QML (Canvas histogram; fidelity mode for
flat designed art, pastel interpretation for photos). A beacon check runs
first: a small, bright, hue-distinct cluster — a lamp, neon sign, sunset
sliver — becomes the accent even though it barely registers in the
histogram, and the dominant field hue steps down to secondary; images
without one behave exactly as before and the script fans it
out to bar/rofi/dunst/kitty/GTK/borders. Dunst's config is symlinked from
`~/.config/dunst/dunstrc` so D-Bus-spawned dunst is themed too.

## Controls

| Module   | Left click        | Right click   | Middle       | Scroll          |
|----------|-------------------|---------------|--------------|-----------------|
| Launcher | rofi drun         | wallpaper picker | random wallpaper | —         |
| Desktop  | focus             | —             | send window  | cycle occupied  |
| Layout   | layout + tweaks panel | —         | —            | cycle layouts   |
| Media    | play/pause        | —             | —            | prev/next track |
| Weather  | 3-day forecast popup | rofi config (city/zip · °C/°F/auto) | — | — |
| Volume   | mute              | pavucontrol   | —            | ±2%             |
| Network  | network app       | nm-connection-editor | —     | —               |
| Tray     | activate          | menu          | secondary    | —               |
| Bell     | toggle do-not-disturb | notification history popup | — | —       |
| Clock    | calendar popup    | —             | —            | —               |
| Caps     | (indicator — appears only while caps lock is on) |||
| Screenshot | flameshot gui   | —             | —            | —               |
| Power    | rofi power menu   | —             | —            | —               |

Keybindings: `super+shift+t` wallpaper picker · `super+n` network app ·
`super+t` cycle layouts.

Bar tweaks: the layout button's Desktop section has **bar height**
(36–72 px) and **element scale** (0.7–2.0×) sliders alongside the bspc
ones. Element scale resizes fonts, icons, module pills, tags, and tray
(popups stay fixed); height is a floor, not a cap — the bar grows to fit
when scaled elements outgrow it. Both persist to plain live-watched
files — `bar-height` and `bar-scale` in the bspwm dir — so `echo 48 >
~/.config/jag-quickshell/bar-height` works identically. Defaults (42 / 1.0) apply
when the files are absent.

Weather config: right-click the module → rofi flow (`scripts/weather`) for
location (city/zip/airport; empty = auto by IP) and units (°F/°C/auto by
locale). State is two plain live-watched files — `weather-location` and
`weather-units` in the bspwm dir — so `echo`/`rm` work identically for
scripts. Location auto-detect follows VPN exit nodes; the popup's 󰍎 line
shows which location the data is actually for.

Design grammar: indicators sit flat on the bar or icon-only (details on
hover); pill backgrounds mean "clickable". One popup per module — no hub:
three hub concepts (card, side panel, expanding deck) were built and
retired; every control lives in its module's obvious place. Anything
needing keyboard input (wifi passwords) is a floating window with its own
qs instance, not a popup. All popups share `Popout.qml` (card chrome +
click-outside/Escape close) — never hand-roll popup chrome. Battery joins
the flat metrics on laptops. VPN state (vpn/wireguard/tun) shows as a
green shield on the network module; the network app can toggle saved VPN
profiles.

## Development notes

- New QML type → add to `qmldir` **and** fully restart (`scripts/bar
  restart`). Hot reload registers no new types and can leave stale handler
  trees running — never trust it for behavior changes.
- Debug: `scripts/bar log` · IPC surface: `scripts/bar ipc show`.

## Fallback

Uncomment the polybar line in bspwmrc and comment the qs line. If quickshell
misbehaves: `scripts/bar restart`.
