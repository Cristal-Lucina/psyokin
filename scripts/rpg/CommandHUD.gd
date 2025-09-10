# scripts/rpg/CommandHUD.gd
# ------------------------------------------------------------------------------
# Bottom command ribbon for manual ally control.
# Provides: Attack / Capture / Defend / Run (Skill/Item stubbed, disabled)
# Shows WEAK/RESIST hints in the Targets list for the Attack action.
# Emits a result dictionary via request_command().
# ------------------------------------------------------------------------------

extends CanvasLayer
class_name CommandHUD

signal command_selected(result: Dictionary)

# UI references
var _root: Control
var _btn_attack: Button
var _btn_capture: Button
var _btn_skill: Button
var _btn_item: Button
var _btn_defend: Button
var _btn_run: Button
var _targets_label: Label
var _targets_list: ItemList
var _actor_label: Label

# Current context
var _for_actor: BattleActor
var _allies: Array[BattleActor] = []
var _enemies: Array[BattleActor] = []
var _needs_target: bool = false
var _pending_action: String = ""

# Map item index -> BattleActor
var _index_to_actor: Array[BattleActor] = []

func _ready() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_right = 1.0
	margin.anchor_top = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_top = -180
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_root.add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	# Left column: heading and current actor
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	hbox.add_child(left)

	var header := Label.new()
	header.text = "Your Turn"
	header.add_theme_font_size_override("font_size", 16)
	left.add_child(header)

	_actor_label = Label.new()
	_actor_label.text = ""
	_actor_label.add_theme_font_size_override("font_size", 14)
	left.add_child(_actor_label)

	# Middle column: actions
	var mid := VBoxContainer.new()
	hbox.add_child(mid)

	_btn_attack = _make_button("Attack", _on_attack_pressed)
	_btn_capture = _make_button("Capture", _on_capture_pressed)
	_btn_skill   = _make_button("Skill", _on_skill_pressed)
	_btn_item    = _make_button("Item", _on_item_pressed)
	_btn_defend  = _make_button("Defend", _on_defend_pressed)
	_btn_run     = _make_button("Run", _on_run_pressed)

	mid.add_child(_btn_attack)
	mid.add_child(_btn_capture)
	mid.add_child(_btn_skill)
	mid.add_child(_btn_item)
	mid.add_child(_btn_defend)
	mid.add_child(_btn_run)

	_btn_skill.disabled = true
	_btn_item.disabled = true

	# Right column: targets list
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	_targets_label = Label.new()
	_targets_label.text = "Targets"
	_targets_label.add_theme_font_size_override("font_size", 14)
	right.add_child(_targets_label)

	_targets_list = ItemList.new()
	_targets_list.select_mode = ItemList.SELECT_SINGLE
	_targets_list.custom_minimum_size = Vector2(320, 120)
	_targets_list.item_activated.connect(_on_target_activated)
	right.add_child(_targets_list)

	hide()

func _make_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(160, 32)
	b.pressed.connect(cb)
	return b

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------
func request_command(for_actor: BattleActor, allies: Array[BattleActor], enemies: Array[BattleActor], has_capture_items: bool) -> Dictionary:
	_for_actor = for_actor
	_allies = allies
	_enemies = enemies

	_actor_label.text = "%s (Lv %d)" % [for_actor.data.name, for_actor.data.level]
	_btn_capture.disabled = not has_capture_items

	_needs_target = false
	_pending_action = ""
	_targets_label.text = "Targets"
	_targets_list.clear()
	_index_to_actor.clear()

	show()
	var result: Dictionary = await command_selected
	hide()
	return result

# ------------------------------------------------------------------------------
# Buttons
# ------------------------------------------------------------------------------
func _on_attack_pressed() -> void:
	_pending_action = "attack"
	_populate_targets(_enemies)
	_needs_target = true

func _on_capture_pressed() -> void:
	if _btn_capture.disabled:
		emit_signal("command_selected", {"type": "defend"})
		return
	_pending_action = "capture"
	_populate_targets(_enemies)
	_needs_target = true

func _on_skill_pressed() -> void:
	emit_signal("command_selected", {"type": "defend"})

func _on_item_pressed() -> void:
	emit_signal("command_selected", {"type": "defend"})

func _on_defend_pressed() -> void:
	emit_signal("command_selected", {"type": "defend"})

func _on_run_pressed() -> void:
	emit_signal("command_selected", {"type": "run"})

# ------------------------------------------------------------------------------
# Targets list (with WEAK/RESIST hints for Attack)
# ------------------------------------------------------------------------------
func _populate_targets(pool: Array[BattleActor]) -> void:
	_targets_list.clear()
	_index_to_actor.clear()

	var show_hints := (_pending_action == "attack")
	var atk_type := 0
	if show_hints and _for_actor != null and _for_actor.data != null and _for_actor.data.weapon != null:
		atk_type = _for_actor.data.weapon.attack_type
	else:
		show_hints = false

	for a in pool:
		if a != null and a.is_alive():
			var line := "%s  HP %d/%d" % [a.data.name, a.current_hp, a.max_hp]
			if show_hints:
				var mult := RPGRules.reaction_multiplier(atk_type, a.data.affinities)
				var tag := RPGRules.reaction_tag(mult)
				if tag != "":
					line += "  (" + tag + ")"
			_targets_list.add_item(line)
			_index_to_actor.append(a)

	if _targets_list.item_count == 0:
		emit_signal("command_selected", {"type": "defend"})

func _on_target_activated(index: int) -> void:
	if not _needs_target:
		return
	if index < 0 or index >= _index_to_actor.size():
		return
	var target := _index_to_actor[index]
	if _pending_action == "attack":
		emit_signal("command_selected", {"type": "attack", "target": target})
	elif _pending_action == "capture":
		emit_signal("command_selected", {"type": "capture", "target": target})
