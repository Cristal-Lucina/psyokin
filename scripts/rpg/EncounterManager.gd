# scripts/rpg/EncounterManager.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Overworld random encounter manager. Tracks player movement distance and
#   periodically rolls for a battle. On success, it generates 1-6 enemies and
#   assigns them to FRONT/BACK rows, then emits a signal with the result.
# WHY:
#   Matches Psyokin's design: single player party, random encounters, front/back rows.
# USE:
#   - Add this as a child of your overworld/Main scene.
#   - Set `player_path` to your Player node so distance can be measured.
#   - Tune exported values in the Inspector.
# LATER:
#   Connect `encounter_started` to a BattleLoader that swaps to a battle scene.
# ------------------------------------------------------------------------------

extends Node
class_name EncounterManager

signal encounter_started(count: int, rows: Array[int], rng_seed: int)

#region Designer Tunables (Inspector)
@export var player_path: NodePath
@export_range(32.0, 2048.0, 1.0) var avg_steps_per_check: float = 256.0
@export_range(0.0, 1.0, 0.01) var encounter_chance: float = 0.25
@export_range(1, 6, 1) var min_enemies: int = 1
@export_range(1, 6, 1) var max_enemies: int = 6
@export_range(0, 3, 1) var front_capacity: int = 3     # How many slots in the front row
@export_range(0.0, 1.0, 0.05) var back_row_bias: float = 0.25
# If true, uses `fixed_seed` for deterministic tests (turn off for production).
@export var use_fixed_seed: bool = false
@export var fixed_seed: int = 12345
# Debug: if true, immediately triggers a single encounter on scene start.
@export var debug_force_encounter_on_start: bool = false
#endregion

#region Internal State
var _player: Node2D
var _rng := RandomNumberGenerator.new()
var _last_pos := Vector2.ZERO
var _distance_accum: float = 0.0
var _next_step_threshold: float = 0.0
#endregion

func _ready() -> void:
	if use_fixed_seed:
		_rng.seed = fixed_seed
	else:
		_rng.randomize()

	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node2D
		if _player == null:
			return
	if _player == null:
		push_warning("EncounterManager: player_path is not set or node not found.")
	_reset_meter()

	if debug_force_encounter_on_start:
		_trigger_encounter_now()

func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	# Accumulate movement distance in pixels
	var p := _player.global_position
	if _last_pos == Vector2.ZERO:
		_last_pos = p
		return
	var moved := p.distance_to(_last_pos)
	_last_pos = p
	_distance_accum += moved

	# When meter passes threshold, roll for encounter and reset
	if _distance_accum >= _next_step_threshold:
		_distance_accum = 0.0
		_next_step_threshold = _draw_threshold()
		_maybe_start_encounter()

func _reset_meter() -> void:
	_distance_accum = 0.0
	_next_step_threshold = _draw_threshold()
	if _player:
		_last_pos = _player.global_position

func _draw_threshold() -> float:
	# Random threshold around the average so it does not feel predictable.
	# Uniform in [0.5 * avg, 1.5 * avg]
	var half := avg_steps_per_check * 0.5
	return _rng.randf_range(avg_steps_per_check - half, avg_steps_per_check + half)

func _maybe_start_encounter() -> void:
	if _rng.randf() <= encounter_chance:
		_trigger_encounter_now()

func _trigger_encounter_now() -> void:
	var seed_used := _rng.randi()
	var count := _rng.randi_range(min_enemies, max_enemies)
	var rows := _assign_rows(count)
	# For now, print and emit. Battle scene will hook this signal.
	print("[Encounter] size=", count, " rows=", rows, " seed=", seed_used)
	emit_signal("encounter_started", count, rows, seed_used)

func _assign_rows(count: int) -> Array[int]:
	# Returns an array of RPGRules.Row values (length == count).
	# Default pattern: fill FRONT up to `front_capacity`, then BACK.
	# Add some randomness with `back_row_bias` to avoid rigid patterns.
	var rows: Array[int] = []
	for i in count:
		# Default row by slot index
		var r := RPGRules.Row.FRONT if i < front_capacity else RPGRules.Row.BACK
		# Random nudge: early slots have a small chance to go BACK, later slots to go FRONT.
		if i < front_capacity:
			if _rng.randf() < back_row_bias:
				r = RPGRules.Row.BACK
		else:
			if _rng.randf() < (1.0 - back_row_bias):
				r = RPGRules.Row.FRONT
		rows.append(r)
	return rows
