# res://scripts/ui/PauseMenu.gd
# -----------------------------------------------------------------------------
# Psyokin Pause Menu (safe build for Godot 4.4.x)
# -----------------------------------------------------------------------------

extends CanvasLayer
class_name PauseMenu

@export var open_on_start: bool = false
@export var dim_bg_color: Color = Color(0, 0, 0, 0.45)
@export var enable_skills_tab: bool = true

var _has_party: bool = false
var _has_skillsdb: bool = false

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _tabs: TabContainer

var _char_dd_stats: OptionButton
var _char_dd_skills: OptionButton

var _stats_level: Label
var _stats_xp: Label
var _stats_next: Label
var _stats_grid_labels: Dictionary = {}   # key -> Label

var _skills_container: VBoxContainer
var _line_by_stat: Dictionary = {}        # { "str": Dictionary, ... }

const MindPanelClass := preload("res://scripts/ui/MindPanel.gd")

const SKILL_DISPLAY: Dictionary = {
	"weapon_focus": "Weapon Focus",
	"trip_capture_boost": "Trip (Capture +)",
	"atk_crit_focus": "Attack Crit Focus",
	"grapple_lock_group_capture": "Grapple Lock (Group Capture)",
	"perfect_atk_plus50": "Perfect ATK (+50% ATK skills)",
	"meteor_clash_ultimate": "Meteor Clash (Ultimate)",
	"use_medium_armor": "Use Medium Armor",
	"shield_plus_80pct_1t": "Shield+ (80% Mitigate, 1 Turn)",
	"use_heavy_armor": "Use Heavy Armor",
	"hp_plus_50pct": "Health+ (+50% Max HP)",
	"team_barrier_1t": "Team Barrier (1 Turn)",
	"no_party_damage_2t_once": "Zero Party Damage (2T, once)",
	"first_to_fight_initiative": "First to Fight (Initiative+)",
	"dodge_up": "Dodge+",
	"armor_accuracy_no_penalty": "Armor Accuracy (No Penalty)",
	"warp_neck_strike_high_crit_vulnerable": "Warp Neck Strike (High Crit, Vulnerable)",
	"double_strike_half_second": "Double Strike (2nd = 1/2)",
	"omni_strike_all_double_high_crit": "Omni Strike (All, Double, High Crit)",
	"healing_plus": "Increased Healing",
	"sigil_training_plus_double_xp": "Sigil Training+ (Double XP)",
	"mana_absorb": "Mana Absorb",
	"mana_plus_50pct": "Mana+ (+50% Max MP)",
	"team_mana_recovery": "Team Mana Recovery",
	"mass_confusion_2t": "Mass Confusion (2 Turns)",
	"psy_attack_focus": "Psy Attack Focus",
	"charm_chat_capture_boost": "Charm Chat (Capture +)",
	"psy_crit_focus": "Psy Crit Focus",
	"mind_trap_group_capture": "Mind Trap (Group Capture)",
	"perfect_psy_plus50": "Perfect PSY (+50% PSY skills)",
	"mind_collapse_ultimate": "Mind Collapse (Ultimate)"
}

# ---------- helpers to avoid Variant warnings ----------
func _get_int_prop(obj: Object, prop_name: String, def: int = 0) -> int:
	if obj == null:
		return def
	if obj.has_method("get"):
		var v: Variant = obj.get(prop_name)
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			return int(v)
	return def

func _get_str_prop(obj: Object, prop_name: String, def: String = "") -> String:
	if obj != null and obj.has_method("get"):
		var v: Variant = obj.get(prop_name)
		if typeof(v) == TYPE_STRING:
			return String(v)
	return def
# -------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_has_party = get_node_or_null("/root/Partystate") != null
	_has_skillsdb = ClassDB.class_exists("SkillsDB")

	if _has_skillsdb:
		_line_by_stat = {
			"str": SkillsDB.STR_UNLOCKS,
			"sta": SkillsDB.STA_UNLOCKS,
			"dex": SkillsDB.DEX_UNLOCKS,
			"intl": SkillsDB.INTL_UNLOCKS,
			"cha": SkillsDB.CHA_UNLOCKS
		}
	else:
		_line_by_stat = {"str": {}, "sta": {}, "dex": {}, "intl": {}, "cha": {}}

	_build_ui()

	# --- Add Mind tab after other tabs are created ---
	_add_mind_tab()
	# -------------------------------------------------

	visible = open_on_start
	_refresh_stats_page()
	_refresh_skills_page()
	print("Sanity OK: PauseMenu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_toggle()

func _toggle() -> void:
	visible = not visible
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = visible

# ---------- UI ----------
func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_left = 0; _root.anchor_right = 1
	_root.anchor_top = 0;  _root.anchor_bottom = 1
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = dim_bg_color
	_dim.anchor_left = 0; _dim.anchor_right = 1
	_dim.anchor_top = 0;  _dim.anchor_bottom = 1
	_root.add_child(_dim)

	var center: CenterContainer = CenterContainer.new()
	center.anchor_left = 0; center.anchor_right = 1
	center.anchor_top = 0;  center.anchor_bottom = 1
	_root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(900, 560)
	center.add_child(_panel)

	var main_v: VBoxContainer = VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 10)
	_panel.add_child(main_v)

	_tabs = TabContainer.new()
	main_v.add_child(_tabs)

	# Stats
	var stats_page: VBoxContainer = VBoxContainer.new()
	stats_page.add_theme_constant_override("separation", 10)
	_tabs.add_child(stats_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Stats")

	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	stats_page.add_child(stats_row)

	var stats_lbl: Label = Label.new()
	stats_lbl.text = "Character:"
	stats_row.add_child(stats_lbl)

	_char_dd_stats = OptionButton.new()
	_char_dd_stats.item_selected.connect(_on_stats_char_changed)
	stats_row.add_child(_char_dd_stats)

	var lv_row: HBoxContainer = HBoxContainer.new()
	lv_row.add_theme_constant_override("separation", 16)
	stats_page.add_child(lv_row)

	_stats_level = Label.new();  _stats_level.text = "Level: —"
	_stats_xp    = Label.new();  _stats_xp.text    = "XP: —"
	_stats_next  = Label.new();  _stats_next.text  = "XP to Next: —"
	lv_row.add_child(_stats_level)
	lv_row.add_child(_stats_xp)
	lv_row.add_child(_stats_next)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	stats_page.add_child(grid)

	_add_stat_line(grid, "Strength", "str")
	_add_stat_line(grid, "Stamina", "sta")
	_add_stat_line(grid, "Dexterity", "dex")
	_add_stat_line(grid, "Intelligence", "intl")
	_add_stat_line(grid, "Charm", "cha")

	# Skills tab (optional)
	if enable_skills_tab:
		var skills_page: VBoxContainer = VBoxContainer.new()
		skills_page.add_theme_constant_override("separation", 10)
		_tabs.add_child(skills_page)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Battle")

		var skills_hdr: Label = Label.new()
		skills_hdr.text = "Skills"
		skills_hdr.add_theme_font_size_override("font_size", 18)
		skills_page.add_child(skills_hdr)

		var skills_row: HBoxContainer = HBoxContainer.new()
		skills_row.add_theme_constant_override("separation", 10)
		skills_page.add_child(skills_row)

		var skills_lbl: Label = Label.new()
		skills_lbl.text = "Character:"
		skills_row.add_child(skills_lbl)

		_char_dd_skills = OptionButton.new()
		_char_dd_skills.item_selected.connect(_on_skills_char_changed)
		skills_row.add_child(_char_dd_skills)

		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		skills_page.add_child(scroll)

		_skills_container = VBoxContainer.new()
		_skills_container.add_theme_constant_override("separation", 4)
		scroll.add_child(_skills_container)

		if not _has_skillsdb:
			var warn: Label = Label.new()
			warn.text = "SkillsDB not found - skills page is a placeholder."
			_skills_container.add_child(warn)
	else:
		var off: VBoxContainer = VBoxContainer.new()
		off.add_child(_placeholder_lbl("Skills tab disabled"))
		_tabs.add_child(off)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Battle")

	# Placeholders
	var items_page: VBoxContainer = VBoxContainer.new()
	items_page.add_child(_placeholder_lbl("Items (WIP)"))
	_tabs.add_child(items_page)
	items_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Items")

	var equip_page: VBoxContainer = VBoxContainer.new()
	equip_page.add_child(_placeholder_lbl("Equipment (WIP)"))
	_tabs.add_child(equip_page)
	equip_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Equipment")

	var quests_page: VBoxContainer = VBoxContainer.new()
	quests_page.add_child(_placeholder_lbl("Quests (WIP)"))
	_tabs.add_child(quests_page)
	quests_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Quests")

	var system_page: VBoxContainer = VBoxContainer.new()
	system_page.add_child(_placeholder_lbl("System (WIP)"))
	_tabs.add_child(system_page)
	system_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "System")

	_populate_character_lists()

# Create the Mind tab as a proper TabContainer page with padding.
func _add_mind_tab() -> void:
	if _tabs == null:
		var t: TabContainer = _find_first_tabcontainer(self)
		if t != null:
			_tabs = t
	if _tabs == null:
		return
	if _tabs.get_node_or_null("Mind") != null:
		return

	# Page with padding
	var page := MarginContainer.new()
	page.name = "Mind"
	page.add_theme_constant_override("margin_left", 24)
	page.add_theme_constant_override("margin_right", 24)
	page.add_theme_constant_override("margin_top", 16)
	page.add_theme_constant_override("margin_bottom", 16)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Mind")

	# Panel inside the page (let the container size it)
	var mind: Control = MindPanelClass.new()
	mind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mind.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(mind)

func _add_stat_line(grid: GridContainer, title: String, key: String) -> void:
	var name_lbl: Label = Label.new()
	name_lbl.text = title
	grid.add_child(name_lbl)

	var val_lbl: Label = Label.new()
	val_lbl.text = "Lv —"
	grid.add_child(val_lbl)

	_stats_grid_labels[key] = val_lbl

func _placeholder_lbl(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	return lbl

# ---------- data helpers ----------
func _party() -> Array:
	if not _has_party:
		return []
	var ps: Object = get_node_or_null("/root/Partystate")
	if ps == null:
		return []
	var m: Variant = ps.get("members")
	return (m as Array) if typeof(m) == TYPE_ARRAY else []

func _populate_character_lists() -> void:
	if _char_dd_stats:
		_char_dd_stats.clear()
	if _char_dd_skills:
		_char_dd_skills.clear()

	var party: Array = _party()
	var count: int = party.size()

	for i in count:
		var cd: Object = party[i]
		var nm: String = _get_str_prop(cd, "name", "Unknown")
		if _char_dd_stats:
			_char_dd_stats.add_item(nm, i)
		if _char_dd_skills:
			_char_dd_skills.add_item(nm, i)

	if count > 0:
		if _char_dd_stats:
			_char_dd_stats.selected = 0
		if _char_dd_skills:
			_char_dd_skills.selected = 0

func _selected_character_from(dd: OptionButton) -> Object:
	var party: Array = _party()
	if dd == null:
		return null
	var idx: int = int(dd.selected)
	if idx < 0 or idx >= party.size():
		return null
	return party[idx]

# ---------- page refresh ----------
func _refresh_stats_page() -> void:
	var cd: Object = _selected_character_from(_char_dd_stats)

	if cd == null:
		_stats_level.text = "Level: —"
		_stats_xp.text = "XP: —"
		_stats_next.text = "XP to Next: —"
		for k in _stats_grid_labels.keys():
			var lab: Label = _stats_grid_labels[k]
			lab.text = "Lv —"
		return

	var lvl: int = _get_int_prop(cd, "level", 0)
	var xp: int  = _get_int_prop(cd, "xp", 0)
	var xpn: int = _get_int_prop(cd, "xp_to_next", 0)

	_stats_level.text = "Level: %d" % lvl
	_stats_xp.text    = "XP: %d" % xp
	_stats_next.text  = "XP to Next: %d" % xpn

	_stats_grid_labels["str"].text  = "Lv %d" % _get_int_prop(cd, "strength", 0)
	_stats_grid_labels["sta"].text  = "Lv %d" % _get_int_prop(cd, "sta", 0)
	_stats_grid_labels["dex"].text  = "Lv %d" % _get_int_prop(cd, "dex", 0)
	_stats_grid_labels["intl"].text = "Lv %d" % _get_int_prop(cd, "intl", 0)
	_stats_grid_labels["cha"].text  = "Lv %d" % _get_int_prop(cd, "cha", 0)

func _rows_less(a: Dictionary, b: Dictionary) -> bool:
	var as_s: String = String(a.get("stat", ""))
	var bs_s: String = String(b.get("stat", ""))
	if as_s == bs_s:
		return int(a.get("req", 0)) < int(b.get("req", 0))
	return as_s < bs_s

func _get_unlocked(slug: String, level: int) -> Array[String]:
	if not _has_skillsdb:
		return []
	return SkillsDB.get_unlocked(slug, level)

func _refresh_skills_page() -> void:
	if not enable_skills_tab or _skills_container == null:
		return

	for child in _skills_container.get_children():
		(child as Node).queue_free()

	var cd: Object = _selected_character_from(_char_dd_skills)
	if cd == null or not _has_skillsdb:
		var lbl: Label = Label.new()
		if _has_skillsdb:
			lbl.text = "Select a character."
		else:
			lbl.text = "SkillsDB not found - skills page is a placeholder."
		_skills_container.add_child(lbl)
		return

	var str_lv: int = _get_int_prop(cd, "strength", 0)
	var sta_lv: int = _get_int_prop(cd, "sta", 0)
	var dex_lv: int = _get_int_prop(cd, "dex", 0)
	var int_lv: int = _get_int_prop(cd, "intl", 0)
	var cha_lv: int = _get_int_prop(cd, "cha", 0)

	var rows: Array[Dictionary] = []
	_flatten_line("str", _line_by_stat.get("str", {}),  _get_unlocked("str", str_lv), rows)
	_flatten_line("sta", _line_by_stat.get("sta", {}),  _get_unlocked("sta", sta_lv), rows)
	_flatten_line("dex", _line_by_stat.get("dex", {}),  _get_unlocked("dex", dex_lv), rows)
	_flatten_line("intl", _line_by_stat.get("intl", {}), _get_unlocked("intl", int_lv), rows)
	_flatten_line("cha", _line_by_stat.get("cha", {}),  _get_unlocked("cha", cha_lv), rows)

	rows.sort_custom(Callable(self, "_rows_less"))

	for row in rows:
		var hb: HBoxContainer = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)

		var tag: Label = Label.new()
		tag.text = String(row.get("stat", "")).to_upper()
		tag.custom_minimum_size = Vector2(48, 0)
		hb.add_child(tag)

		var sid: String = String(row.get("id", ""))
		var disp: String = String(SKILL_DISPLAY.get(sid, sid))

		var nm: Label = Label.new()
		nm.text = disp
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nm)

		var req: Label = Label.new()
		req.text = "Req Lv %d" % int(row.get("req", 0))
		hb.add_child(req)

		var lit: bool = bool(row.get("unlocked", false))
		var status: Label = Label.new()
		status.text = "ACTIVE" if lit else "LOCKED"
		status.modulate = (Color(1,1,1,1) if lit else Color(0.6,0.6,0.6,1))
		hb.add_child(status)

		_skills_container.add_child(hb)

# table: {level(int) : Array[String]}
func _flatten_line(stat_slug: String, table: Dictionary, unlocked: Array[String], out_rows: Array[Dictionary]) -> void:
	for k in table.keys():
		var req: int = int(k)
		var arr_any: Variant = table[k]
		if typeof(arr_any) != TYPE_ARRAY:
			continue
		var arr: Array = arr_any
		for sid_any in arr:
			var sid: String = String(sid_any)
			out_rows.append({
				"stat": stat_slug,
				"req": req,
				"id": sid,
				"unlocked": unlocked.has(sid)
			})

# ---------- find TabContainer utility ----------
func _find_first_tabcontainer(node: Node) -> TabContainer:
	if node is TabContainer:
		return node as TabContainer
	for child in node.get_children():
		var t: TabContainer = _find_first_tabcontainer(child)
		if t != null:
			return t
	return null

# ---------- signals ----------
func _on_stats_char_changed(_index: int) -> void:
	_refresh_stats_page()

func _on_skills_char_changed(_index: int) -> void:
	_refresh_skills_page()
