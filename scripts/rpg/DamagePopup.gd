# res://scripts/rpg/DamagePopup.gd
extends Node2D
class_name DamagePopup

@export var text: String = "" : set = set_text
@export var lifetime_sec: float = 1.60
@export var rise_pixels: float = 36.0
@export var font_size: int = 18
@export var color: Color = Color(1, 1, 1, 1)

var _age: float = 0.0
var _start_pos: Vector2

func set_text(v: String) -> void:
	text = v
	queue_redraw()

func _ready() -> void:
	_start_pos = global_position
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	var t: float = clamp(_age / lifetime_sec, 0.0, 1.0)
	# Ease-out rise
	var y_off: float = -rise_pixels * (1.0 - pow(1.0 - t, 2.0))
	global_position = _start_pos + Vector2(0.0, y_off)
	modulate.a = 1.0 - t
	if _age >= lifetime_sec:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var f: Font = ThemeDB.fallback_font
	if f == null:
		return
	var sz: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# Center horizontally above the node
	var pos: Vector2 = Vector2(-sz.x * 0.5, 0.0)
	# Godot 4 signature: draw_string(font, pos, text, halign, width, size, color)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
