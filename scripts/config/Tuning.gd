# Tuning.gd — Inspector sliders for balance knobs (HP only for now)
# Attach this to a Node named "Tuning" (either as an Autoload scene or as a child under Player).
# All values are saved with the scene.

extends Node
class_name Tuning

# --- HP tuning knobs (show as sliders in Inspector) ---------------------------
@export_range(0, 500, 1)  var HP_BASE_ALLY: int = 16
@export_range(0, 10, 1)   var HP_PER_STA_ALLY: int = 3
@export_range(0.0, 2.0, .05) var HP_LVL_SCALE_ALLY: float = 0.75

@export_range(0, 500, 1)  var HP_BASE_ENEMY: int = 10
@export_range(0, 10, 1)   var HP_PER_STA_ENEMY: int = 2
@export_range(0.0, 2.0, .05) var HP_LVL_SCALE_ENEMY: float = 0.50
# Optional: quick description to sanity-check in a debugger/log.
func describe() -> String:
	return "HP = %d + (STA * %d) + int(level * %.2f) * STA" % [HP_BASE_ALLY, HP_PER_STA_ALLY, HP_LVL_SCALE_ALLY]
