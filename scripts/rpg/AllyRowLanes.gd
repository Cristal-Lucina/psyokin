# scripts/rpg/AllyRowLanes.gd
# ------------------------------------------------------------------------------
# Draws two translucent lane panels for ALLY rows (FRONT/BACK) on the battlefield.
# You give it two Rect2s in world coordinates and it positions ColorRects + Labels.
# ------------------------------------------------------------------------------
extends Node2D
class_name AllyRowLanes

@export var front_color: Color = Color(0.15, 0.30, 0.55, 0.15)
@export var back_color: Color  = Color(0.15, 0.55, 0.30, 0.15)
@export var label_color: Color = Color(1, 1, 1, 0.9)
@export var label_size: int = 14
@export var z: int = -60

var _front_rect: ColorRect
var _front_label: Label
var _back_rect: ColorRect
var _back_label: Label

func _ready() -> void:
	z_index = z
	# Build minimal UI nodes once; we'll size/position them in configure()
	_front_rect = ColorRect.new()
	_front_rect.color = front_color
	_front_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_front_rect)

	_front_label = Label.new()
	_front_label.text = "FRONT"
	_front_label.modulate = label_color
	_front_label.add_theme_font_size_override("font_size", label_size)
	_front_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front_rect.add_child(_front_label)

	_back_rect = ColorRect.new()
	_back_rect.color = back_color
	_back_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back_rect)

	_back_label = Label.new()
	_back_label.text = "BACK"
	_back_label.modulate = label_color
	_back_label.add_theme_font_size_override("font_size", label_size)
	_back_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_rect.add_child(_back_label)

# Configure with world-space rectangles
func configure(front: Rect2, back: Rect2) -> void:
	# Position in world space (Node2D), but ColorRects are Controls, which use local
	# coordinates in their parent. We put them directly as children of this Node2D,
	# so we can assign their position to the same world-space values and the tree
	# will render them at those places.
	_front_rect.position = front.position
	_front_rect.size = front.size
	_front_label.position = (_front_rect.size * 0.5) - (_front_label.get_minimum_size() * 0.5)

	_back_rect.position = back.position
	_back_rect.size = back.size
	_back_label.position = (_back_rect.size * 0.5) - (_back_label.get_minimum_size() * 0.5)
