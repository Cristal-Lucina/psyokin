# Psyokin (Godot 4)

2D RPG prototype. Godot 4.4.1-stable_win64.
Project root: `C:\GameDev\Projects\psyokin`.

How to run:
- Open `psyokin` in Godot 4.4.1
- Play: F5

Main scenes:
- `scenes/Main.tscn`
- `scenes/Battle.tscn`
- `scenes/Results.tscn`

## Codebase Overview

- `scenes/` – main Godot scenes such as the overworld, battle, and results screens.
- `scripts/` – game logic and supporting code:
  - `rpg/` contains the battle system, character data, progression, and related gameplay logic.
  - `ui/` implements menus like character creation and the pause menu.
  - `config/` holds tuning parameters and other configuration.
  - `integrations/` includes interfaces to external services.
- `plugins/` – editor plugins, currently including the Godot Git plugin.
- `project.godot` – the Godot project configuration file.
