extends Node2D
class_name BattleScene

@export_file("*.tscn") var return_scene_path: String = "res://scenes/Main.tscn"

const XP_BASE_PER_LEVEL: int = 100
const AUTO_CAPTURE_THRESHOLD: float = 0.35

const HUD_SCRIPT_PATH := "res://scripts/rpg/BattleHUD.gd"
const POPUP_SCRIPT_PATH := "res://scripts/rpg/DamagePopup.gd"
const COMMAND_HUD_PATH := "res://scripts/rpg/CommandHUD.gd"

var rules: RPGRules = RPGRules.new()
var formation: Formation = Formation.new()

@onready var _ctx: BattleContext = _get_battle_context()
@onready var _party: PartyState = get_node_or_null("/root/Partystate") as PartyState
@onready var _results_bus: ResultsContext = get_node_or_null("/root/Resultscontext") as ResultsContext

var allies: Array[BattleActor] = []
var enemies: Array[BattleActor] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _defeated_enemy_levels: Array[int] = []
var _captured: Array[String] = []
var _capture_stacks: Array[Dictionary] = []

var _to_free: Array[Node] = []
var _is_finishing: bool = false
var _cmd_ui: CommandHUD

func _ready() -> void:
	_rng.randomize()

	# Camera
	var cam: Camera2D = Camera2D.new()
	cam.enabled = true
	add_child(cam)
	cam.make_current()
	cam.global_position = (formation.ally_origin + formation.enemy_origin) * 0.5

	# Background
	if ClassDB.class_exists("WorldDebugGrid"):
		var grid: Node2D = WorldDebugGrid.new()
		grid.z_index = -100
		add_child(grid)
	else:
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.10, 0.10, 0.12, 1.0)
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.z_index = -100
		add_child(bg)

	# Encounter request
	var count: int
	var rows: Array[int]
	if _ctx != null and _ctx.pending:
		count = _ctx.count
		rows = _ctx.rows.duplicate()
		_ctx.clear()
	else:
		count = 3
		rows = [RPGRules.Row.FRONT, RPGRules.Row.FRONT, RPGRules.Row.BACK]

	_spawn_allies_from_party()
	_spawn_enemies(count, rows)
	_seed_capture_inventory()

	# HUD
	var hud_script: Script = load(HUD_SCRIPT_PATH) as Script
	if hud_script != null:
		var hud_obj: Object = hud_script.new()
		if hud_obj is CanvasLayer:
			var hud_layer: CanvasLayer = hud_obj as CanvasLayer
			add_child(hud_layer)
			if hud_layer.has_method("bind_actors"):
				hud_layer.call("bind_actors", allies, enemies)

	# Command ribbon
	var cmd_script: Script = load(COMMAND_HUD_PATH) as Script
	if cmd_script != null:
		var cmd_obj: Object = cmd_script.new()
		if cmd_obj is CommandHUD:
			_cmd_ui = cmd_obj as CommandHUD
			add_child(_cmd_ui)

	await get_tree().process_frame
	await _run_battle_loop()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_finish_and_show_results()

# ---------------------- Spawning & wiring ---------------------------------
func _wire_actor(actor: BattleActor, into_enemies: bool) -> void:
	if into_enemies:
		enemies.append(actor)
		actor.died.connect(_on_enemy_died)
	else:
		allies.append(actor)
		actor.died.connect(_on_ally_died)

	# Signal now emits (actor, new_hp)
	actor.hp_changed.connect(_on_actor_hp_changed)

func _spawn_allies_from_party() -> void:
	var pos: Array[Vector2] = formation.get_ally_positions()
	if _party == null:
		push_error("PartyState autoload '/root/Partystate' missing. Using temporary allies.")
		for i in 3:
			var a: BattleActor = BattleActor.new()
			var r: int = (RPGRules.Row.FRONT if i == 0 else RPGRules.Row.BACK)
			var data_t: CharacterData = _make_sample_ally(i)
			data_t.refresh_xp_to_next()
			a.setup(data_t, r, false, rules)
			add_child(a)
			a.global_position = pos[i]
			_wire_actor(a, false)
		return

	_party.ensure_seed(rules)
	var n: int = min(3, _party.members.size())
	for i in n:
		var actor: BattleActor = BattleActor.new()
		var r2: int = (RPGRules.Row.FRONT if i == 0 else RPGRules.Row.BACK)
		var d: CharacterData = _party.members[i]
		actor.setup(d, r2, false, rules)
		add_child(actor)
		actor.global_position = pos[i]
		_wire_actor(actor, false)

func _spawn_enemies(count: int, rows: Array[int]) -> void:
	var pos: Array[Vector2] = formation.get_enemy_positions_for_rows(rows)
	for i in count:
		var e: BattleActor = BattleActor.new()
		e.setup(_make_sample_enemy(i), rows[i], true, rules)
		e.died.connect(_on_enemy_died)
		add_child(e)
		e.global_position = pos[i]
		_wire_actor(e, true)

func _record_defeated(dead: BattleActor) -> void:
	_defeated_enemy_levels.append(dead.data.level)

func _remove_enemy_deferred(target: BattleActor) -> void:
	var idx: int = enemies.find(target)
	if idx >= 0:
		enemies.remove_at(idx)
	target.visible = false
	target.set_process(false)
	target.set_physics_process(false)
	_to_free.append(target)

# ---------------------- Turn flow -----------------------------------------
func _initiative_order() -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	for a in allies:
		if a.is_alive():
			var ini_a: int = RPGRules.initiative(a.data.eff_dex(), a.data.total_armor_limit(), rules.roll_d20())
			order.append({ "actor": a, "ini": ini_a })
	for e in enemies:
		if e.is_alive():
			var ini_e: int = RPGRules.initiative(e.data.eff_dex(), e.data.total_armor_limit(), rules.roll_d20())
			order.append({ "actor": e, "ini": ini_e })
	order.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return int(x["ini"]) > int(y["ini"])
	)
	return order

func _run_battle_loop() -> void:
	while true:
		var order: Array[Dictionary] = _initiative_order()
		if order.is_empty():
			break

		for item in order:
			var obj: Object = item.get("actor")
			if not is_instance_valid(obj):
				continue
			var actor: BattleActor = obj as BattleActor
			if actor == null or not actor.is_alive():
				continue

			var pre: int = _check_victory()
			if pre != 0:
				_finish_and_show_results()
				return

			if actor.is_enemy:
				_enemy_take_turn(actor)
			else:
				await _ally_take_turn(actor)

			await _safe_delay(0.25)

		_flush_deferred_frees()
		var post: int = _check_victory()
		if post != 0:
			_finish_and_show_results()
			return

func _enemy_take_turn(actor: BattleActor) -> void:
	var living: Array[BattleActor] = []
	for a in allies:
		if a.is_alive():
			living.append(a)
	if living.is_empty():
		return
	var target: BattleActor = living[_rng.randi_range(0, living.size() - 1)]

	var base_dmg: int = actor.perform_basic_attack(target)
	if base_dmg <= 0:
		return

	_apply_reaction_row_damage_and_popup(actor, target, base_dmg)

func _ally_take_turn(actor: BattleActor) -> void:
	if _cmd_ui == null:
		_enemy_take_turn(actor)
		return

	var has_capture: bool = false
	for s in _capture_stacks:
		if int(s["count"]) > 0:
			has_capture = true
			break

	var result: Dictionary = await _cmd_ui.request_command(actor, allies, enemies, has_capture)
	var t: String = String(result.get("type", ""))

	if t == "run":
		_finish_and_show_results()
		return

	if t == "defend":
		_spawn_popup("GUARD", actor.global_position)
		return

	if t == "attack":
		var target_a: BattleActor = result.get("target") as BattleActor
		if target_a != null and target_a.is_alive():
			var base_dmg: int = actor.perform_basic_attack(target_a)
			if base_dmg > 0:
				_apply_reaction_row_damage_and_popup(actor, target_a, base_dmg)
		return

	if t == "capture":
		var target_c: BattleActor = result.get("target") as BattleActor
		if target_c != null and target_c.is_alive():
			if not has_capture:
				_spawn_popup("NO ITEMS", actor.global_position)
			else:
				var captured: bool = _attempt_capture(actor, target_c)
				if captured:
					await _safe_delay(0.4)
					var w: int = _check_victory()
					if w != 0:
						_finish_and_show_results()
		return

# Centralized reaction/row post-processing
func _apply_reaction_row_damage_and_popup(attacker: BattleActor, target: BattleActor, base_dmg: int) -> void:
	var attack_type: int = RPGRules.AttackType.SLASH
	if attacker.data.weapon != null:
		attack_type = int(attacker.data.weapon.attack_type)

	var element_mult: float = RPGRules.reaction_multiplier(attack_type, target.data.affinities)
	var tag: String = RPGRules.reaction_tag(element_mult)

	var row_off: float = RPGRules.row_offense_multiplier(attacker.row)
	var row_def: float = RPGRules.row_defense_multiplier(target.row)
	var total_mult: float = element_mult * row_off * row_def

	var final_dmg: int = int(round(float(base_dmg) * total_mult))
	final_dmg = max(0, final_dmg)

	# Apply only the extra to hit final number (base was already applied).
	var extra: int = max(0, final_dmg - base_dmg)
	if extra > 0 and target.is_alive():
		target.apply_damage(extra)

	var element_pct: int = int(round(element_mult * 100.0))
	var off_pct: int = int(round(row_off * 100.0))
	var def_pct: int = int(round(row_def * 100.0))
	var total_pct: int = int(round(total_mult * 100.0))

	var txt: String = "%d" % final_dmg
	if tag != "":
		txt += " " + tag + "  [%d%% * %d%% * %d%% = %d%%]" % [element_pct, off_pct, def_pct, total_pct]
	_spawn_popup(txt, target.global_position)

# ---------------------- Victory & cleanup ---------------------------------
func _check_victory() -> int:
	var any_allies: bool = false
	for a in allies:
		if a.is_alive():
			any_allies = true
			break
	var any_enemies: bool = false
	for e in enemies:
		if e.is_alive():
			any_enemies = true
			break
	if not any_enemies and not any_allies:
		return 0
	if not any_enemies:
		return +1
	if not any_allies:
		return -1
	return 0

func _flush_deferred_frees() -> void:
	for n in _to_free:
		if is_instance_valid(n):
			n.queue_free()
	_to_free.clear()

# ---------------------- Results -------------------------------------------
func _finish_and_show_results() -> void:
	if _is_finishing:
		return
	_is_finishing = true

	_flush_deferred_frees()

	var allies_summary: Array[Dictionary] = []
	for a in allies:
		if not a.is_alive():
			continue

		var xp_total: int = 0
		for elvl in _defeated_enemy_levels:
			var base: int = XP_BASE_PER_LEVEL * elvl
			var mult: float = Progression.xp_multiplier(a.data.level, elvl)
			xp_total += int(round(float(base) * mult))

		var lvl_before: int = a.data.level
		var xp_before: int = a.data.xp
		var xptn_before: int = a.data.xp_to_next

                var levels_gained: int = a.data.add_xp(xp_total)

                if a.data.bracelet != null:
                        for s in a.data.bracelet.equipped_sigils():
                                var gain := 1
                                if a.sigil_use_counts.has(s):
                                        gain += int(a.sigil_use_counts[s])
                                s.gain_xp(gain)

                var lvl_after: int = a.data.level
                var xp_after: int = a.data.xp
                var xptn_after: int = a.data.xp_to_next

                allies_summary.append({
                        "name": a.data.name,
                        "level_before": lvl_before,
                        "level_after": lvl_after,
                        "xp_gained": xp_total,
                        "xp_before": xp_before,
                        "xp_to_next_before": xptn_before,
                        "xp_after": xp_after,
                        "xp_to_next_after": xptn_after,
                        "levels_gained": levels_gained
                })

	if _results_bus != null:
		_results_bus.set_results(allies_summary, _captured.duplicate(), [], return_scene_path)
		var err: int = get_tree().change_scene_to_file("res://scenes/Results.tscn")
		if err != OK:
			push_error("BattleScene: failed to open results; returning to main.")
			_return_to_main()
	else:
		for e in allies_summary:
			print(e)
		_return_to_main()

func _return_to_main() -> void:
	var err: int = get_tree().change_scene_to_file(return_scene_path)
	if err != OK:
		push_error("Failed to return to main: %s" % str(err))

# ---------------------- Capture -------------------------------------------
func _seed_capture_inventory() -> void:
	var strong: CaptureItem = CaptureItem.new()
	strong.name = "Snare Mk-II"
	strong.base_rate = 0.45
	strong.tier = 2

	var basic: CaptureItem = CaptureItem.new()
	basic.name = "Snare Mk-I"
	basic.base_rate = 0.25
	basic.tier = 1

	_capture_stacks = [
		{ "item": strong, "count": 2 },
		{ "item": basic,  "count": 4 }
	]

func _should_attempt_capture(target: BattleActor) -> bool:
	if _capture_stacks.is_empty():
		return false
	var hp_ratio: float = float(target.current_hp) / float(target.max_hp)
	return hp_ratio <= AUTO_CAPTURE_THRESHOLD

func _attempt_capture(user_actor: BattleActor, target: BattleActor) -> bool:
	var stack_idx: int = -1
	for i in _capture_stacks.size():
		if int(_capture_stacks[i]["count"]) > 0:
			stack_idx = i
			break
	if stack_idx == -1:
		return false

	var item: CaptureItem = _capture_stacks[stack_idx]["item"]
	var hp_ratio: float = float(target.current_hp) / float(target.max_hp)
	var chance: float = Progression.capture_chance(user_actor.data.eff_cha(), target.data.level, hp_ratio, item.base_rate)
	var roll: float = _rng.randf()

	_capture_stacks[stack_idx]["count"] = int(_capture_stacks[stack_idx]["count"]) - 1

	if roll <= chance:
		_captured.append("%s Lv.%d" % [target.data.name, target.data.level])
		_record_defeated(target)
		_remove_enemy_deferred(target)
		_spawn_popup("CAPTURED", target.global_position)
		return true
	else:
		_spawn_popup("RESIST", target.global_position)
		return false

# ---------------------- Visual helpers ------------------------------------
func _spawn_popup(txt: String, world_pos: Vector2) -> void:
	var popup_script: Script = load(POPUP_SCRIPT_PATH) as Script
	if popup_script != null:
		var p_obj: Object = popup_script.new()
		if p_obj is Node2D:
			var pnode: Node2D = p_obj as Node2D
			pnode.set("text", txt)
			add_child(pnode)
			pnode.global_position = world_pos + Vector2(0, -20)
	else:
		print("[POPUP]", txt, "@", world_pos)

# ---------------------- Signals -------------------------------------------
func _on_enemy_died(actor: BattleActor) -> void:
	_record_defeated(actor)
	_remove_enemy_deferred(actor)

func _on_ally_died(_actor: BattleActor) -> void:
	# handled by victory check
	pass

func _on_actor_hp_changed(_actor: BattleActor, _new_hp: int) -> void:
	# If you keep HUD refs here, refresh them.
	pass

# ---------------------- Utils ---------------------------------------------
func _get_battle_context() -> BattleContext:
	var ctx: BattleContext = get_node_or_null("/root/BattleContext") as BattleContext
	if ctx == null:
		ctx = get_node_or_null("/root/Battlecontext") as BattleContext
	return ctx

func _safe_delay(seconds: float) -> void:
	if _is_finishing or not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	await tree.create_timer(seconds).timeout

# ---------------------- Sample data ---------------------------------------
func _make_sample_weapon(w_name: String, dice_expr: String, limit: int, type_id: int) -> Weapon:
	var w: Weapon = Weapon.new()
	w.name = w_name
	w.dice = dice_expr
	w.weapon_limit = limit
	w.attack_type = type_id
	return w

func _make_sample_armor(a_name: String, val: int, lim: int) -> Armor:
	var ar: Armor = Armor.new()
	ar.name = a_name
	ar.armor_value = val
	ar.armor_limit = lim
	return ar

func _make_sample_boots(b_name: String, val: int, lim: int) -> Boots:
	var b: Boots = Boots.new()
	b.name = b_name
	b.armor_value = val
	b.armor_limit = lim
	return b

func _make_sample_bracelet(sta_bonus: int) -> Bracelet:
	var br: Bracelet = Bracelet.new()
	br.name = "Bracelet"
	br.slot_count = 1
	br.bonus_sta = sta_bonus
	return br

func _make_sample_enemy(index: int) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.name = "Enemy" + str(index + 1)
	c.level = 3
	c.xp = 0
	c.refresh_xp_to_next()
	c.strength = 5
	c.sta = 5
	c.dex = 4
	c.intl = 3
	c.cha = 3
	c.affinities = [RPGRules.AttackType.IMPACT, RPGRules.AttackType.FIRE]
	c.weapon = _make_sample_weapon("Claws", "1d4", 0, RPGRules.AttackType.SLASH)
	c.armor = _make_sample_armor("Hide", 0, 0)
	c.boots = _make_sample_boots("None", 0, 0)
	c.bracelet = _make_sample_bracelet(0)
	return c

func _make_sample_ally(index: int) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.name = "Ally" + str(index + 1)
	c.level = 3
	c.xp = 0
	c.refresh_xp_to_next()
	c.strength = 6 - index
	c.sta = 5
	c.dex = 5 + index
	c.intl = 4
	c.cha = 4
	c.affinities = [RPGRules.AttackType.SLASH]
	c.weapon = _make_sample_weapon("Katana", "1d6+4", 1, RPGRules.AttackType.SLASH)
	c.armor = _make_sample_armor("Gi", 1, 0)
	c.boots = _make_sample_boots("Light Boots", 1, 0)
	c.bracelet = _make_sample_bracelet(1)
	return c
