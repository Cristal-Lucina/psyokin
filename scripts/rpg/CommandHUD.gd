# scripts/rpg/CommandHUD.gd
# ------------------------------------------------------------------------------
# Command ribbon for manual turns.
# - Buttons: Attack / Skill / Capture / Defend / Run
# - Collects skills from CharacterData.skills (Array[StringName]) and from
#   bracelet sigils' unlock_skill_ids (Array[StringName])
# - Target pickers for Attack / Capture / Skill (single target)
# - Returns a Dictionary via `command_ready`:
#     {"type": String, "target": BattleActor|null, "skill_id": StringName|null}
# Godot 4.x safe. No scene file required; UI is built programmatically.
# ------------------------------------------------------------------------------

extends CanvasLayer
class_name CommandHUD

signal command_ready(result: Dictionary)

# --- UI nodes -------------------------------------------------------------
var _root: Control
var _panel: PanelContainer
var _ribbon: HBoxContainer
var _details: VBoxContainer
var _targets_box: VBoxContainer
var _skills_box: VBoxContainer

# --- State ---------------------------------------------------------------
var _actor: BattleActor
var _allies: Array[BattleActor] = []
var _enemies: Array[BattleActor] = []
var _has_capture: bool = false
var _awaiting: bool = false

func _ready() -> void:
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

# Public API: await this from BattleScene
func request_command(actor: BattleActor, allies: Array[BattleActor], enemies: Array[BattleActor], has_capture: bool) -> Dictionary:
	_actor = actor
	_allies = allies
	_enemies = enemies
	_has_capture = has_capture

	_show_ribbon_for_actor()
	visible = true
	_awaiting = true

	var result: Dictionary = await self.command_ready
	visible = false
	_clear_details()
	_awaiting = false
	return result

# --- UI construction ------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_left = 0
	_root.anchor_right = 1
	_root.anchor_top = 0
	_root.anchor_bottom = 1
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(980, 220)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.pivot_offset = Vector2(490, 110)
	_panel.position = Vector2(-490, -240)
	_root.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)

	_ribbon = HBoxContainer.new()
	_ribbon.add_theme_constant_override("separation", 12)
	v.add_child(_ribbon)

	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 8)
	v.add_child(_details)

	_targets_box = VBoxContainer.new()
	_skills_box = VBoxContainer.new()
	_details.add_child(_targets_box)
	_details.add_child(_skills_box)

func _clear_details() -> void:
	for node in _targets_box.get_children():
		node.queue_free()
	for node in _skills_box.get_children():
		node.queue_free()
	_targets_box.visible = false
	_skills_box.visible = false

func _clear_ribbon() -> void:
	for node in _ribbon.get_children():
		node.queue_free()

func _mk_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	return b

# --- Ribbon ---------------------------------------------------------------

func _show_ribbon_for_actor() -> void:
	_clear_ribbon()
	_clear_details()

	var can_attack := _alive_enemies().size() > 0
	var can_capture := _has_capture and can_attack
	var can_skill := _collect_actor_skills(_actor).size() > 0

	var b_attack := _mk_button("Attack")
	b_attack.disabled = not can_attack
	b_attack.pressed.connect(Callable(self, "_on_attack_pressed"))
	_ribbon.add_child(b_attack)

	var b_skill := _mk_button("Skill")
	b_skill.disabled = not can_skill
	b_skill.pressed.connect(Callable(self, "_on_skill_pressed"))
	_ribbon.add_child(b_skill)

	var b_capture := _mk_button("Capture")
	b_capture.disabled = not can_capture
	b_capture.pressed.connect(Callable(self, "_on_capture_pressed"))
	_ribbon.add_child(b_capture)

	var b_defend := _mk_button("Defend")
	b_defend.pressed.connect(Callable(self, "_on_defend_pressed"))
	_ribbon.add_child(b_defend)

	var b_run := _mk_button("Run")
	b_run.pressed.connect(Callable(self, "_on_run_pressed"))
	_ribbon.add_child(b_run)

# --- Target picker --------------------------------------------------------

func _alive_enemies() -> Array[BattleActor]:
	var out: Array[BattleActor] = []
	for e in _enemies:
		if e != null and e.is_alive():
			out.append(e)
	return out

func _show_target_picker(mode: String, chosen_skill: StringName = StringName("")) -> void:
	_clear_details()
	_targets_box.visible = true

	var lbl := Label.new()
	lbl.text = "Choose Target:"
	_targets_box.add_child(lbl)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	_targets_box.add_child(list)

	var alive := _alive_enemies()
	if alive.is_empty():
		var none := Label.new()
		none.text = "No valid targets."
		_targets_box.add_child(none)
	else:
		for e in alive:
			var btn := Button.new()
			btn.text = "%s  HP %d/%d" % [e.data.name, e.current_hp, e.max_hp]
			btn.pressed.connect(Callable(self, "_on_target_chosen").bind(mode, e, chosen_skill))
			list.add_child(btn)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(Callable(self, "_on_back_from_targets"))
	_targets_box.add_child(back)

# --- Skill picker ---------------------------------------------------------

func _collect_actor_skills(actor: BattleActor) -> Array[StringName]:
	var out: Array[StringName] = []
	if actor == null or actor.data == null:
		return out

	# Character’s learned skills
	for sid in actor.data.skills:
		if typeof(sid) == TYPE_STRING_NAME and not out.has(sid):
			out.append(sid)

	# Sigil unlocks
	var br := actor.data.bracelet
	if br != null and (br as Object).has_method("get"):
		var sigils_v: Variant = br.get("sigils")
		if typeof(sigils_v) == TYPE_ARRAY:
			var arr: Array = sigils_v
			for s_v in arr:
				if s_v == null:
					continue
				var ids_v: Variant = (s_v as Object).get("unlock_skill_ids")
				if typeof(ids_v) == TYPE_ARRAY:
					var ids: Array = ids_v
					for id_v in ids:
						if typeof(id_v) == TYPE_STRING_NAME:
							var sid2: StringName = id_v
							if not out.has(sid2):
								out.append(sid2)
	return out

func _show_skill_picker() -> void:
	_clear_details()
	_skills_box.visible = true

	var lbl := Label.new()
	lbl.text = "Choose Skill:"
	_skills_box.add_child(lbl)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	_skills_box.add_child(list)

	var skills: Array[StringName] = _collect_actor_skills(_actor)
	if skills.is_empty():
		var none := Label.new()
		none.text = "No skills available."
		_skills_box.add_child(none)
	else:
		for sid in skills:
			var btn := Button.new()
			btn.text = String(sid)
			btn.pressed.connect(Callable(self, "_on_skill_chosen").bind(sid))
			list.add_child(btn)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(Callable(self, "_on_back_from_skills"))
	_skills_box.add_child(back)

# --- Button handlers ------------------------------------------------------

func _on_attack_pressed() -> void:
	if _alive_enemies().is_empty():
		return
	_show_target_picker("attack")

func _on_skill_pressed() -> void:
	_show_skill_picker()

func _on_capture_pressed() -> void:
	if not _has_capture or _alive_enemies().is_empty():
		return
	_show_target_picker("capture")

func _on_defend_pressed() -> void:
	_emit_and_finish({"type": "defend"})

func _on_run_pressed() -> void:
	_emit_and_finish({"type": "run"})

func _on_back_from_targets() -> void:
	_show_ribbon_for_actor()

func _on_back_from_skills() -> void:
	_show_ribbon_for_actor()

func _on_skill_chosen(sid: StringName) -> void:
	# After picking a skill, choose a target
	_show_target_picker("skill", sid)

func _on_target_chosen(mode: String, target: BattleActor, chosen_skill: StringName) -> void:
	if mode == "attack":
		_emit_and_finish({"type": "attack", "target": target})
	elif mode == "capture":
		_emit_and_finish({"type": "capture", "target": target})
	elif mode == "skill":
		_emit_and_finish({"type": "skill", "skill_id": chosen_skill, "target": target})

# --- Emit and finish ------------------------------------------------------

func _emit_and_finish(result: Dictionary) -> void:
	if not _awaiting:
		return
	emit_signal("command_ready", result)
