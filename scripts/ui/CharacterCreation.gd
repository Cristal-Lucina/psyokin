# res://scripts/ui/CharacterCreation.gd
# -----------------------------------------------------------------------------
# Character Creation screen for Psyokin (Godot 4.4.x)
# - Identity: name, pronoun, body type, genital type
# - Stat allocation: 30-point pool; per-level costs [3,3,4,4,5,5,6,6,7,7]; cap 10
# - On Confirm: builds CharacterData, installs into /root/Partystate at index 0,
#   stores identity via set_meta(), and changes scene to Main.tscn.
# - Includes a sanity test print of skill unlocks via SkillsDB.get_unlocked().
# -----------------------------------------------------------------------------

extends Control
class_name CharacterCreation

@export_file("*.tscn") var next_scene: String = "res://scenes/Main.tscn"

var _profile: PlayerProfile = PlayerProfile.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# UI refs
var _remaining_lbl: Label
var _rows: Dictionary = {}   # key PlayerProfile.Stat -> { "name":Label, "lvl":Label, "cost":Label }

# Dropdowns / inputs
var _dd_pronoun: OptionButton
var _dd_body: OptionButton
var _dd_genital: OptionButton
var _name_edit: LineEdit

func _ready() -> void:
	_build_ui()
	_refresh_all()

# ------------------------------- UI Builders ----------------------------------

func _build_ui() -> void:
	anchor_left = 0
	anchor_right = 1
	anchor_top = 0
	anchor_bottom = 1

	var root := MarginContainer.new()
	root.anchor_left = 0
	root.anchor_right = 1
	root.anchor_top = 0
	root.anchor_bottom = 1
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	root.add_child(v)

	# Title
	var title := Label.new()
	title.text = "Create Your Character"
	title.add_theme_font_size_override("font_size", 22)
	v.add_child(title)

	# Identity box
	var id_box := VBoxContainer.new()
	id_box.add_theme_constant_override("separation", 8)
	v.add_child(id_box)

	# Name row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	id_box.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = "Name:"
	name_lbl.custom_minimum_size = Vector2(80, 0)
	name_row.add_child(name_lbl)

	_name_edit = LineEdit.new()
	_name_edit.text = _profile.name
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_edit)

	# Pronoun / Body / Genital row
	var pbg_row := HBoxContainer.new()
	pbg_row.add_theme_constant_override("separation", 12)
	id_box.add_child(pbg_row)

	_dd_pronoun = _make_dd(["He/Him", "She/Her", "They/Them", "Any"])
	pbg_row.add_child(_labeled_box("Pronoun:", _dd_pronoun))

	_dd_body = _make_dd(["Slim", "Average", "Athletic"])
	pbg_row.add_child(_labeled_box("Body:", _dd_body))

	_dd_genital = _make_dd(["none", "penis", "vagina"])
	pbg_row.add_child(_labeled_box("Genital:", _dd_genital))

	# Remaining points header
	_remaining_lbl = Label.new()
	_remaining_lbl.add_theme_font_size_override("font_size", 18)
	v.add_child(_remaining_lbl)

	# Stat grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.custom_minimum_size = Vector2(620, 0)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)

	# Header row
	_add_grid_header(grid, "Stat")
	_add_grid_header(grid, "Level")
	_add_grid_header(grid, "Next Cost")
	_add_grid_header(grid, "")
	_add_grid_header(grid, "")

	# Rows for each stat
	_add_stat_row(grid, PlayerProfile.Stat.STR)
	_add_stat_row(grid, PlayerProfile.Stat.STA)
	_add_stat_row(grid, PlayerProfile.Stat.DEX)
	_add_stat_row(grid, PlayerProfile.Stat.INTL)
	_add_stat_row(grid, PlayerProfile.Stat.CHA)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	v.add_child(spacer)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	v.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(confirm_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(_on_reset)
	btn_row.add_child(reset_btn)

# Helper to make an OptionButton
func _make_dd(items: Array[String]) -> OptionButton:
	var dd := OptionButton.new()
	for s in items:
		dd.add_item(s) # auto-ids; we'll use 'selected' index when reading
	return dd

# Label + control boxed together
func _labeled_box(caption: String, ctrl: Control) -> VBoxContainer:
	var vb := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = caption
	vb.add_child(lbl)
	vb.add_child(ctrl)
	return vb

func _add_grid_header(grid: GridContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	grid.add_child(lbl)

func _add_stat_row(grid: GridContainer, st: PlayerProfile.Stat) -> void:
	var name_lbl := Label.new()
	name_lbl.text = PlayerProfile.stat_to_name(st)
	grid.add_child(name_lbl)

	var lvl_lbl := Label.new()
	grid.add_child(lvl_lbl)

	var cost_lbl := Label.new()
	grid.add_child(cost_lbl)

	var plus := Button.new()
	plus.text = "+"
	plus.pressed.connect(func() -> void:
		if _profile.increase(st):
			_refresh_all()
	)
	grid.add_child(plus)

	var minus := Button.new()
	minus.text = "-"
	minus.pressed.connect(func() -> void:
		if _profile.decrease(st):
			_refresh_all()
	)
	grid.add_child(minus)

	_rows[st] = { "name": name_lbl, "lvl": lvl_lbl, "cost": cost_lbl }

# ------------------------------- Refresh --------------------------------------

func _refresh_all() -> void:
	# Identity fields → profile (use selected INDEX, not id)
	_profile.name = _name_edit.text.strip_edges()

	var idx_body: int = _dd_body.selected
	var idx_gen: int = _dd_genital.selected
	var idx_pro: int = _dd_pronoun.selected

	_profile.body_type = _dd_body.get_item_text(idx_body)
	_profile.genital_type = _dd_genital.get_item_text(idx_gen)

	match idx_pro:
		0: _profile.pronoun_choice = PlayerProfile.Pronoun.HE
		1: _profile.pronoun_choice = PlayerProfile.Pronoun.SHE
		2: _profile.pronoun_choice = PlayerProfile.Pronoun.THEY
		3: _profile.pronoun_choice = PlayerProfile.Pronoun.ANY
		_: _profile.pronoun_choice = PlayerProfile.Pronoun.ANY

	_remaining_lbl.text = "Points Remaining: %d" % _profile.remaining

	# Per-row levels and next costs
	_update_row(PlayerProfile.Stat.STR, _profile.level_str)
	_update_row(PlayerProfile.Stat.STA, _profile.level_sta)
	_update_row(PlayerProfile.Stat.DEX, _profile.level_dex)
	_update_row(PlayerProfile.Stat.INTL, _profile.level_intl)
	_update_row(PlayerProfile.Stat.CHA, _profile.level_cha)

func _update_row(st: PlayerProfile.Stat, lvl: int) -> void:
	var row: Dictionary = _rows[st]
	var lvl_lbl: Label = row["lvl"]
	var cost_lbl: Label = row["cost"]
	lvl_lbl.text = "Lv %d" % lvl
	var cost: int = _profile.next_cost(st)
	var at_cap: bool = (lvl >= _profile.CREATION_MAX_LEVEL)
	cost_lbl.text = (("—" if at_cap else str(cost)))

# ------------------------------- Buttons --------------------------------------

func _on_reset() -> void:
	_profile = PlayerProfile.new()
	_refresh_all()

func _on_confirm() -> void:
	if _profile.name.is_empty():
		push_warning("Please enter a name.")
		return

	_profile.finalize_pronoun(_rng)

	# Convert to CharacterData and seed minimal safe gear.
	var cd := CharacterData.new()
	cd.name = _profile.name
	cd.level = 1
	cd.xp = 0
	cd.refresh_xp_to_next()

	# Apply starting stat levels
	cd.strength = _profile.level_str
	cd.sta = _profile.level_sta
	cd.dex = _profile.level_dex
	cd.intl = _profile.level_intl
	cd.cha = _profile.level_cha

	# Minimal safe gear
	if cd.weapon == null:
		cd.weapon = Weapon.new()
		cd.weapon.name = "Training Stick"
		cd.weapon.dice = "1d4"
		cd.weapon.weapon_limit = 0
		cd.weapon.attack_type = RPGRules.AttackType.SLASH

	if cd.armor == null:
		cd.armor = Armor.new()
		cd.armor.name = "Cloth"
		cd.armor.armor_value = 0
		cd.armor.armor_limit = 0

	if cd.boots == null:
		cd.boots = Boots.new()
		cd.boots.name = "Sneakers"
		cd.boots.armor_value = 0
		cd.boots.armor_limit = 0

	if cd.bracelet == null:
		cd.bracelet = Bracelet.new()
		cd.bracelet.name = "Basic Bracelet"
		cd.bracelet.slot_count = 1
		cd.bracelet.bonus_sta = 0

	# Store identity via Object metadata (safe on any Object/RefCounted).
	# Retrieve later with cd.get_meta("pronoun"), etc.
	cd.set_meta("pronoun", int(_profile.pronoun_final))  # store enum as int
	cd.set_meta("body_type", _profile.body_type)
	cd.set_meta("genital_type", _profile.genital_type)

	# Install into Partystate autoload as protagonist at index 0.
	var ps := get_node_or_null("/root/Partystate") as PartyState
	if ps == null:
		push_error("Partystate autoload missing; cannot install protagonist.")
		return

	if ps.members.is_empty():
		ps.members.append(cd)
	else:
		ps.members[0] = cd

	# Optional: mark protagonist index if your systems expect it.
	ps.set("protagonist_index", 0)

	# --- Sanity test: print starting unlocked skills for each stat -------------
	var str_sk: Array[String] = SkillsDB.get_unlocked("str", cd.strength)
	var sta_sk: Array[String] = SkillsDB.get_unlocked("sta", cd.sta)
	var dex_sk: Array[String] = SkillsDB.get_unlocked("dex", cd.dex)
	var int_sk: Array[String] = SkillsDB.get_unlocked("intl", cd.intl)
	var cha_sk: Array[String] = SkillsDB.get_unlocked("cha", cd.cha)
	print("Unlocked @start -> STR:", str_sk, " STA:", sta_sk, " DEX:", dex_sk, " INT:", int_sk, " CHA:", cha_sk)
	# --------------------------------------------------------------------------

	# Continue to main scene
	var err: int = get_tree().change_scene_to_file(next_scene)
	if err != OK:
		push_error("Failed to open next scene: %d" % err)
