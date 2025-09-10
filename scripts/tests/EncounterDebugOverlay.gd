extends Node2D
class_name EncounterDebugOverlay

@export var manager_path: NodePath
@export_range(0.5, 10.0, 0.5) var preview_duration: float = 3.0
@export var show_allies: bool = true
@export var show_enemies: bool = true

@export var ally_radius: float = 14.0
@export var enemy_half: float = 16.0
@export var ally_fill: Color = Color(0.20, 0.40, 1.00, 0.90)
@export var ally_outline: Color = Color(0, 0, 0, 0.90)
@export var enemy_front_fill: Color = Color(1.00, 0.20, 0.20, 0.90)
@export var enemy_back_fill: Color  = Color(1.00, 0.60, 0.20, 0.90)
@export var enemy_outline: Color    = Color(0, 0, 0, 0.90)

var _manager: EncounterManager
var _formation: Formation = Formation.new()
var _ally_pos: Array[Vector2] = []
var _enemy_rows: Array[int] = []
var _enemy_pos: Array[Vector2] = []
var _time_left: float = 0.0

func _ready() -> void:
	if manager_path != NodePath():
		_manager = get_node_or_null(manager_path)
	if _manager == null:
		push_warning("EncounterDebugOverlay: manager_path not set or node not found.")
		return
	_manager.connect("encounter_started", Callable(self, "_on_encounter_started"))
	_ally_pos = _formation.get_ally_positions()

func _process(delta: float) -> void:
	if _time_left > 0.0:
		_time_left = max(0.0, _time_left - delta)
		queue_redraw()

func _on_encounter_started(count: int, rows: Array[int], rng_seed: int) -> void:
	_enemy_rows = rows
	_enemy_pos = _formation.get_enemy_positions_for_rows(rows)
	_time_left = preview_duration
	queue_redraw()
	print("[EncounterPreview] count=", count, " rows=", rows, " pos=", _enemy_pos, " seed=", rng_seed)

func _draw() -> void:
	if _time_left <= 0.0:
		return

	var t: float = clamp(_time_left / preview_duration, 0.0, 1.0)
	var fade := 0.35 + 0.65 * t

	if show_allies:
		for p in _ally_pos:
			draw_circle(p, ally_radius, ally_fill * Color(1, 1, 1, fade))
			draw_circle(p, ally_radius, ally_outline, 2.0)

	if show_enemies:
		for i in _enemy_pos.size():
			var p: Vector2 = _enemy_pos[i]
			var is_back: bool = (_enemy_rows[i] == RPGRules.Row.BACK)
			var fill: Color = (enemy_back_fill if is_back else enemy_front_fill) * Color(1, 1, 1, fade)
			var r := Rect2(p - Vector2(enemy_half, enemy_half), Vector2(enemy_half, enemy_half) * 2.0)
			draw_rect(r, fill)
			draw_rect(r, enemy_outline, false, 2.0)
