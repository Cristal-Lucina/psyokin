# scripts/rpg/ResultsScreen.gd
# ------------------------------------------------------------------------------
# Centered post-battle summary UI with:
#   - Aligned 4-column table (Name, Lvl Before, Lvl After, XP Gained)
#   - Progress section: XP bars per ally (before -> after) + LEVEL UP badge
# ------------------------------------------------------------------------------

extends Control
class_name ResultsScreen

@onready var _ctx: ResultsContext = get_node("/root/Resultscontext") as ResultsContext

func _ready() -> void:
	# Fill screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Outer margins
	var margins := MarginContainer.new()
	margins.anchor_right = 1.0
	margins.anchor_bottom = 1.0
	margins.add_theme_constant_override("margin_left", 24)
	margins.add_theme_constant_override("margin_right", 24)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_bottom", 24)
	add_child(margins)

	# Center the content block (both axes)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_child(center)

	# Panel holds everything; fixed width keeps columns visible
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	# Inner padding so content is not flush with the panel edges
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(pad)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	pad.add_child(root)

	# Title
	var title := Label.new()
	title.text = "Battle Results"
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)

	# Allies section header
	var allies_title := Label.new()
	allies_title.text = "Allies"
	allies_title.add_theme_font_size_override("font_size", 18)
	root.add_child(allies_title)

	# Table (4 columns) – fixed widths so headers align with rows
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	root.add_child(grid)

	var W_NAME := 240   # name column
	var W_NUM  := 120   # each numeric column

	# Header row
	grid.add_child(_hdr_w("Name", W_NAME))
	grid.add_child(_hdr_w("Lvl Before", W_NUM))
	grid.add_child(_hdr_w("Lvl After",  W_NUM))
	grid.add_child(_hdr_w("XP Gained",  W_NUM))

	# Data rows
	if _ctx != null and _ctx.has_data:
		for entry_any in _ctx.allies:
			var entry: Dictionary = entry_any
			var name_s: String = String(entry.get("name", ""))
			var lvl_b: int = int(entry.get("level_before", 0))
			var lvl_a: int = int(entry.get("level_after", lvl_b))
			var xp_g: int = int(entry.get("xp_gained", 0))

			grid.add_child(_cell_w(name_s, W_NAME, true))
			grid.add_child(_cell_w(str(lvl_b), W_NUM))
			grid.add_child(_cell_w(str(lvl_a), W_NUM))
			grid.add_child(_cell_w(str(xp_g), W_NUM))

	# Progress bars section
	var prog_title := Label.new()
	prog_title.text = "Progress"
	prog_title.add_theme_font_size_override("font_size", 18)
	root.add_child(prog_title)

	var prog_box := VBoxContainer.new()
	prog_box.add_theme_constant_override("separation", 8)
	root.add_child(prog_box)

	if _ctx != null and _ctx.has_data:
		for entry_any in _ctx.allies:
			var entry: Dictionary = entry_any
			_add_progress_row(prog_box, entry)

	# Captured section
	var cap_title := Label.new()
	cap_title.text = "Captured"
	cap_title.add_theme_font_size_override("font_size", 18)
	root.add_child(cap_title)

	var cap_box := VBoxContainer.new()
	root.add_child(cap_box)

	if _ctx != null and _ctx.has_data and not _ctx.captured.is_empty():
		for name_s in _ctx.captured:
			var l := Label.new()
			l.text = "• " + name_s
			cap_box.add_child(l)
	else:
		var none := Label.new()
		none.text = "• None"
		cap_box.add_child(none)

	# Spacer inside panel (keeps button near panel bottom)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	# Centered Continue button
	var btn_row := HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(btn_row)

	var btn := Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(160, 40)
	btn.pressed.connect(_on_continue_pressed)
	btn_row.add_child(btn)

# ---------- helpers ----------
func _hdr_w(text_s: String, width_px: int) -> Label:
	var l := Label.new()
	l.text = text_s
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(width_px, 0)
	return l

func _cell_w(text_s: String, width_px: int, word_wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text_s
	l.add_theme_font_size_override("font_size", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(width_px, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD if word_wrap else TextServer.AUTOWRAP_OFF
	return l

func _add_progress_row(parent: VBoxContainer, entry: Dictionary) -> void:
	# Pull both BEFORE and AFTER if present; otherwise fall back to AFTER only.
	var name_s: String = String(entry.get("name", ""))
	var lvl_b: int = int(entry.get("level_before", 0))
	var lvl_a: int = int(entry.get("level_after", lvl_b))

	var xp_before: int = int(entry.get("xp_before", -1))
	var xp_to_next_before: int = int(entry.get("xp_to_next_before", -1))
	var xp_after: int = int(entry.get("xp_after", -1))
	var xp_to_next_after: int = int(entry.get("xp_to_next_after", -1))

	# Header row: Name + LEVEL UP badge if level increased
	var head := HBoxContainer.new()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_constant_override("separation", 8)

	var name_lbl := Label.new()
	name_lbl.text = name_s
	name_lbl.add_theme_font_size_override("font_size", 14)
	head.add_child(name_lbl)

	if lvl_a > lvl_b:
		var badge := Label.new()
		badge.text = "LEVEL UP!"
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		head.add_child(badge)

	parent.add_child(head)

	# Progress bar line
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 18)

	var start_pct: float = 0.0
	var end_pct: float = 0.0

	if xp_after >= 0 and xp_to_next_after > 0:
		end_pct = clamp((float(xp_after) / float(xp_to_next_after)) * 100.0, 0.0, 100.0)
	if xp_before >= 0 and xp_to_next_before > 0:
		start_pct = clamp((float(xp_before) / float(xp_to_next_before)) * 100.0, 0.0, 100.0)
	else:
		start_pct = end_pct  # fallback if we only know AFTER

	bar.value = start_pct
	parent.add_child(bar)

	# Tiny caption: "X / Y XP to next"
	var cap := Label.new()
	if xp_after >= 0 and xp_to_next_after > 0:
		cap.text = "%d / %d XP to next" % [xp_after, xp_to_next_after]
	else:
		cap.text = ""
	cap.add_theme_font_size_override("font_size", 12)
	parent.add_child(cap)

	# Animate from BEFORE -> AFTER if both are known
	if start_pct != end_pct:
		var tween := create_tween()
		tween.tween_property(bar, "value", end_pct, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_continue_pressed() -> void:
	if _ctx != null and _ctx.has_data:
		var ret := _ctx.return_scene_path
		_ctx.clear()
		var err := get_tree().change_scene_to_file(ret)
		if err != OK:
			push_error("ResultsScreen: failed to return to %s" % ret)
	else:
		var err2 := get_tree().change_scene_to_file("res://scenes/Main.tscn")
		if err2 != OK:
			push_error("ResultsScreen: failed to change scene.")
