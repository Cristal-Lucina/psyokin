# scripts/rpg/BattleActor.gd
# ------------------------------------------------------------------------------
# Minimal battle actor using CharacterData. Safe gear access via get() so
# parse/load order doesn't matter. Uses queue_redraw() (Godot 4.x).
# ------------------------------------------------------------------------------

extends Node2D
class_name BattleActor

signal died(actor: BattleActor)
signal hp_changed(actor: BattleActor, new_hp: int)

var data: CharacterData
var rules: RPGRules
var is_enemy: bool = false
var row: int = RPGRules.Row.FRONT

var max_hp: int = 1
var current_hp: int = 1

var _name_hp_label: Label
var sigil_use_counts: Dictionary = {}

func setup(cd: CharacterData, row_id: int, enemy: bool, r: RPGRules) -> void:
	data = cd
	row = row_id
	is_enemy = enemy
	rules = r

	var side := (RPGRules.Side.ENEMY if is_enemy else RPGRules.Side.ALLY)
	max_hp = RPGRules.hp_from_stats(data.eff_sta(), data.level, side)
	current_hp = max_hp

	_build_labels()
	_refresh_labels()
	queue_redraw()

# Returns base physical damage BEFORE elemental/row multipliers
func perform_basic_attack(target: BattleActor) -> int:
	var base := RPGRules.atk_damage(data)            # STR part
	var rolled := data.roll_weapon_damage(rules)     # weapon dice part
	base += rolled

	# Accuracy check
	var acc := RPGRules.atk_accuracy(data)
	var dodge := RPGRules.atk_dodge(target.data)
	if acc < dodge:
		return 0

	# Apply the base amount immediately to target (your pipeline does base first)
	if base > 0:
		target.apply_damage(base)
	return base

func perform_skill(skill_id: String, target: BattleActor) -> void:
	if skill_id == "":
		return
	if not ClassDB.class_exists("SkillLibrary"):
		return
	var skill: Skill = SkillLibrary.create(skill_id)
	if skill == null:
		return
	skill.perform(self, target)

func record_sigil_use(s: Sigil) -> void:
	if s == null:
		return
	var c := int(sigil_use_counts.get(s, 0))
	sigil_use_counts[s] = c + 1

# Damage & death
func apply_damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current_hp = max(0, current_hp - amount)
	_refresh_labels()
	emit_signal("hp_changed", self, current_hp)
	if current_hp <= 0:
		emit_signal("died", self)

func is_alive() -> bool:
	return current_hp > 0

# Visuals
func _build_labels() -> void:
	if _name_hp_label == null:
		_name_hp_label = Label.new()
		_name_hp_label.position = Vector2(-36, -36)
		add_child(_name_hp_label)

func _refresh_labels() -> void:
	if is_instance_valid(_name_hp_label):
		_name_hp_label.text = "%s  HP %d/%d" % [data.name, current_hp, max_hp]

func _draw() -> void:
	var r := 10.0
	if is_enemy:
		var rect := Rect2(Vector2(-r, -r), Vector2(2.0*r, 2.0*r))
		draw_rect(rect, Color(0.85, 0.15, 0.15), true, 2.0)
		draw_rect(rect, Color(0, 0, 0), false, 2.0)
	else:
		draw_circle(Vector2.ZERO, r, Color(0.1, 0.1, 0.12))
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0, 0, 0), 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()
