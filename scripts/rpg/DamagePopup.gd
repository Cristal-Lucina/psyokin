# scripts/rpg/DamagePopup.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Simple floating text popup for damage numbers.
# USE:
#   Instance with a text, add_child near target, and it will float and disappear.
# ------------------------------------------------------------------------------

extends Node2D
class_name DamagePopup

@export var text: String = ""
@export var duration: float = 0.6
@export var rise_pixels: float = 24.0

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.modulate = Color(1, 1, 1, 1)
	_label.pivot_offset = Vector2.ZERO
	_label.position = Vector2.ZERO
	add_child(_label)

	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -rise_pixels), duration)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(self, "_on_done"))

func _on_done() -> void:
	queue_free()
