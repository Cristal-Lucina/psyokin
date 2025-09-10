# scripts/rpg/TurnTimeline.gd
# ------------------------------------------------------------------------------
# Turn order list (left side) with dependable slide-in/out handle (Godot 4).
# Public API (unchanged):
#   show_order(order: Array[Dictionary])   # { "actor": BattleActor, "ini": int }
#   mark_index(i: int)
#   dim_actor(actor: BattleActor)
# ------------------------------------------------------------------------------
extends CanvasLayer
class_name TurnTimeline

# Layout
@export var panel_width: int = 220
@export var row_height: int = 28
@export var row_gap: int = 4
@export var top_margin: int = 64         # vertical offset to sit below your HP HUD
@export var dock_left_px: int = 0        # horizontal dock offset (push right to avoid overlap)

# Slide handle + animation
@export var handle_width: int = 20
@export var slide_duration: float = 0.22
@export var start_open: bool = true

# Colors
@export var color_bg: Color = Color(0, 0, 0, 0.35)
@export var color_enemy: Color = Color(0.75, 0.2, 0.2, 1)
@export var color_ally: Color = Color(0.22, 0.45, 0.9, 1)
@export var color_pro: Color = Color(0.95, 0.8, 0.25, 1)
@export var color_active: Color = Color(1, 1, 1, 1)
@export var color_inactive: Color = Color(0.88, 0.88, 0.88, 1)
@export var color_dim: Color = Color(0.45, 0.45, 0.45, 1)
@export var color_handle: Color = Color(0.12, 0.12, 0.12, 0.9)

# Fonts
@export var font_size_main: int = 13
@export var font_size_small: int = 11

# Sliding root (we animate position.x), fixed content, handle
var _root: Control
var _content: Control
var _bg: ColorRect
var _vbox: VBoxContainer
var _handle_btn: Button

# State
var _row_by_id: Dictionary = {}
var _rows: Array[Control] = []
var _current_index: int = -1
var _is_open: bool = true

# Positions
var _open_x: float = 0.0           # root.position.x when open
var _closed_x: float = 0.0         # when closed (only handle visible)

func _ready() -> void:
	layer = 10  # ensure it sits above most HUD; tweak if needed

	# Root node we physically move
	_root = Control.new()
	_root.anchor_left = 0
	_root.anchor_right = 0
	_root.anchor_top = 0
	_root.anchor_bottom = 0
	_root.position = Vector2(0, float(top_margin))
	_root.size = Vector2(float(panel_width + handle_width), ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child(_root)

	# Content (panel) area, fixed width
	_content = Control.new()
	_content.anchor_left = 0
	_content.anchor_right = 0
	_content.anchor_top = 0
	_content.anchor_bottom = 1
	_content.offset_left = 0
	_content.offset_right = panel_width
	_content.offset_top = 0
	_content.offset_bottom = 0
	_root.add_child(_content)

	# Background panel
	_bg = ColorRect.new()
	_bg.color = color_bg
	_bg.anchor_left = 0
	_bg.anchor_right = 1
	_bg.anchor_top = 0
	_bg.anchor_bottom = 1
	_content.add_child(_bg)

	# Rows container
	_vbox = VBoxContainer.new()
	_vbox.anchor_left = 0
	_vbox.anchor_right = 1
	_vbox.anchor_top = 0
	_vbox.anchor_bottom = 1
	_vbox.offset_left = 6
	_vbox.offset_right = -6
	_vbox.offset_top = 6
	_vbox.offset_bottom = -6
	_vbox.add_theme_constant_override("separation", row_gap)
	_content.add_child(_vbox)

	# Handle button (stays at right edge of the sliding root)
	_handle_btn = Button.new()
	_handle_btn.text = "Turns"
	_handle_btn.focus_mode = Control.FOCUS_NONE
	_handle_btn.anchor_left = 1
	_handle_btn.anchor_right = 1
	_handle_btn.anchor_top = 0
	_handle_btn.anchor_bottom = 1
	_handle_btn.offset_left = -handle_width
	_handle_btn.offset_right = 0
	_handle_btn.offset_top = 0
	_handle_btn.offset_bottom = 0
	_root.add_child(_handle_btn)

	var handle_bg := ColorRect.new()
	handle_bg.color = color_handle
	handle_bg.anchor_left = 0
	handle_bg.anchor_right = 1
	handle_bg.anchor_top = 0
	handle_bg.anchor_bottom = 1
	_handle_btn.add_child(handle_bg)
	handle_bg.move_to_front()

	_handle_btn.pressed.connect(_on_handle_pressed)

	# Compute docked positions
	# Open: panel's left edge at dock_left_px
	_open_x = float(dock_left_px)
	# Closed: move left so only the handle is visible at dock_left_px
	_closed_x = float(dock_left_px - panel_width)

	_is_open = start_open
	_root.position.x = (_open_x if _is_open else _closed_x)

# ------------------------------ Public API ------------------------------------
func show_order(order: Array) -> void:
	_row_by_id.clear()
	_rows.clear()
	for c in _vbox.get_children():
		c.queue_free()
	_current_index = -1

	for item in order:
		var actor: BattleActor = item.get("actor") as BattleActor
		var ini: int = int(item.get("ini", 0))
		if actor == null:
			continue
		var row: Control = _make_row(actor, ini)
		_vbox.add_child(row)
		_row_by_id[actor.get_instance_id()] = row
		_rows.append(row)

	_mark_none_active()

func mark_index(i: int) -> void:
	_current_index = i
	var idx: int = 0
	for row in _rows:
		if row == null or not is_instance_valid(row):
			idx += 1
			continue
		var is_dim: bool = bool(row.get_meta("dim", false))
		if is_dim:
			row.modulate = color_dim
		else:
			row.modulate = (color_active if idx == i else color_inactive)
		idx += 1

func dim_actor(actor: BattleActor) -> void:
	if actor == null:
		return
	var row: Control = _row_by_id.get(actor.get_instance_id(), null)
	if row != null and is_instance_valid(row):
		row.set_meta("dim", true)
		row.modulate = color_dim

# ------------------------------ Handle / Slide --------------------------------
func _on_handle_pressed() -> void:
	_is_open = not _is_open
	_slide_to(_open_x if _is_open else _closed_x)

func _slide_to(target_x: float) -> void:
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_root, "position:x", target_x, slide_duration)

# ------------------------------- Row factory ----------------------------------
func _make_row(actor: BattleActor, ini: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_width - 12, row_height)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate = color_inactive
	panel.set_meta("dim", false)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(h)

	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(6, row_height - 6)
	stripe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stripe.color = (color_enemy if actor.is_enemy else (color_pro if actor.is_protagonist else color_ally))
	h.add_child(stripe)

	var name_lbl := Label.new()
	name_lbl.text = actor.data.name
	name_lbl.add_theme_font_size_override("font_size", font_size_main)
	name_lbl.clip_text = true
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(name_lbl)

	var right := Label.new()
	right.add_theme_font_size_override("font_size", font_size_small)
	var row_ch: String = ("F" if actor.row == RPGRules.Row.FRONT else "B")
	right.text = "INI %d  [%s]" % [ini, row_ch]
	right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(right)

	return panel

func _mark_none_active() -> void:
	for row in _rows:
		if row == null or not is_instance_valid(row):
			continue
		var is_dim: bool = bool(row.get_meta("dim", false))
		row.modulate = (color_dim if is_dim else color_inactive)
