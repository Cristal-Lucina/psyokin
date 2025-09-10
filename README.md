# Psyokin (Godot 4)

2D RPG prototype. Godot 4.4.1-stable_win64.
Project root: `C:\GameDev\Projects\psyokin`.
Godot path: `C:\GameDev\Editor\Godot4.4.1`.

How to run:
- Ensure the Godot executable directory is on your `PATH`.
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
## Psyokin – Dev Brief (for AI collaborator)

### Repo/Engine/Branch info
- **Repo:** psyokin
- **Engine:** Godot 4.4.1
- **Branch:** work (based on main)

### High-level vision
Psyokin is a top-down 2D RPG prototype focused on turn-based battles and party progression.

### What’s implemented now
- Basic overworld movement and battle transitions
- Turn-based battle loop with party and enemy actors
- Results screen summarizing encounter outcomes
- Party seeding for quick development iteration

### Key singletons/autoloads
- `BattleContext` – passes encounter setup between scenes
- `ResultsContext` – stores battle results for the results screen
- `PartyState` – persistent roster of player characters
- `OpenAIClient` – placeholder integration point for external AI
- `BalanceTuning` – scene exposing runtime tuning knobs

### Important scripts/scenes
- `scenes/Main.tscn` – overworld entry point
- `scenes/Battle.tscn` – core battle scene
- `scenes/Results.tscn` – post-battle summary
- `scripts/rpg/PartyState.gd` – manages party members
- `scripts/rpg/BattleContext.gd` – holds pending encounter info
- `scripts/rpg/ResultsContext.gd` – temporary storage for battle outcomes
- `scripts/config/Tuning.gd` – exported balance variables
- `scripts/integrations/OpenAIClient.gd` – example external service hook

### Coding conventions
- UTF-8 encoding enforced via `.editorconfig`
- 8-space indentation in GDScript
- `snake_case` for functions and variables
- `PascalCase` for classes
- Heavily commented headers summarizing each script’s role

### How to run

1. Install Godot 4.4.1 and add `C:\GameDev\Projects\psyokin\Editor\Godot4.4.1` to your system `PATH` so the `godot` command is available.
2. Open `project.godot` in the editor.
3. Press **F5** to play.

### Tuning knobs
- `scripts/config/Tuning.gd` exports HP-related sliders used by `BalanceTuning`
- Adjust `HP_BASE_*`, `HP_PER_STA_*`, and `HP_LVL_SCALE_*` to rebalance health formulas

### Skills system state
- `scripts/rpg/SkillsDB.gd` maps stat levels to unlocked skill IDs
- Unlock tables exist for STR, STA, DEX, INTL, and CHA lines

### Known pain points
- Combat balance and skill effects are placeholder
- No save/load; roster resets each run
- Minimal UI polish
- Limited documentation beyond this brief

### “What I want you to do next” task list
- Implement actual skill effects and integrate with battle actors
- Add enemy AI behaviors and encounter variety
- Persist party progression with a save system
- Expand tuning system to cover more stats and mechanics
- Improve battle and overworld UI/UX

### Style & docs notes
- Keep file headers with `WHAT/USE/RESPONSIBILITIES` sections
- Document exported properties and singletons
- Favor small, focused scripts over large monoliths

### File-level notes
- `scenes/Tuning.tscn` autoloads as `BalanceTuning` for live tweaking
- `scripts/tests` contain smoke tests and debug overlays
- `OpenAIClient.gd` is a stub for future integrations

### How to verify
- Launch `Main.tscn` and trigger a battle to ensure flow works
- Adjust tuning sliders and confirm HP formula via `Tuning.describe()`
- Run smoke tests in the editor to catch regressions
