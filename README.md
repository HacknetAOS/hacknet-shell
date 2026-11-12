# hacknet-shell

[![CI](https://github.com/HacknetAOS/hacknet-shell/actions/workflows/ci.yml/badge.svg)](https://github.com/HacknetAOS/hacknet-shell/actions/workflows/ci.yml)

Quickshell (QtQuick / `wlr-layer-shell`) desktop environment, login greeter, and compositor session scripts for HacknetAOS.

## Layout

```
  [TOP BAR: RAM / CPU / CLOCK / SEARCH / SETTINGS / SESSION]
  ┌───────────────┬───────────────────────────────┐
  │  VISUALIZER   │                               │
  │  (CAVA Audio) │      DISPLAY STAGE            │
  ├───────────────┤  (Single-deck active window)  │
  │    NETMAP     │                               │
  │  (Topology)   ├───────────────────────────────┤
  │               │      TERMINAL PANE            │
  │               │   (Docked terminals 0..N)     │
  └───────────────┴───────────────────────────────┘
```

## Directory Structure

- `shell.qml` — Main desktop shell entrypoint.
- `singletons/` — Shared state singletons (`Daemon`, `Geo`, `Notifs`, `Theme`, `Ui`).
- `components/` — Panel and modal QML components (`TopBar`, `Visualizer`, `NetMap`, `StageFrame`, `AppLauncher`, `SettingsPanel`, `LockScreen`, etc.).
- `greeter/` — `greetd` login interface (`LoginView`, `PreLoginView`, `HexBackground`, `PowerModal`).
- `compositor/` — Sway (`sway/hacknet.conf`) and Hyprland (`hyprland/hacknet.lua`) configs.
- `bin/` — Session launchers (`hacknet-sway`, `hacknet-hyprland`, `hacknet-greeter`) and helpers (`hacknet-launcher`, `hacknet-apps`, `hacknet-term`, `hacknet-dock-term`).

## Default Keybindings

| Keybinding | Action |
|---|---|
| `Super` / `Super+Space` | Toggle App Opener (`hacknet-launcher`) |
| `Super+Enter` | Spawn docked terminal (`hacknet-dock-term`) |
| `Super+Shift+Enter` | Spawn stage terminal (`hacknet-term --app-id hacknet-stage`) |
| `Super+Tab` / `Super+Shift+Tab` | Cycle stage windows (`hacknetctl cycle`) |
| `Super+E` | Launch `thunar` in stage |
| `Super+Q` / `Super+W` | Close focused window |
| `Super+1..5` | Switch virtual desktop |
| `Print` | Save screenshot to `~/Pictures` |
