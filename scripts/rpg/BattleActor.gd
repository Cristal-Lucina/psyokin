# scripts/rpg/BattleActor.gd
# ------------------------------------------------------------------------------
# Minimal battle actor with HP signals and simple drawing.
# Godot 4.x safe (queue_redraw instead of update()).
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

# simple label (created at runtime)
var _name_hp_label: Label
var sigil_use_counts: Dictionary = {}

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
func setup(cd: CharacterData, row_id: int, enemy: bool, r: RPGRules) -> void:
	data = cd
	row = row_id
	is_enemy = enemy
	rules = r

	# HP from BalanceTuning (different sliders for allies/enemies)
	var side: int = (RPGRules.Side.ENEMY if is_enemy else RPGRules.Side.ALLY)
	max_hp    = RPGRules.hp_from_stats(data.sta, data.level, side)
	current_hp = max_hp

	_build_labels()
	_refresh_labels()
	queue_redraw()

# ------------------------------------------------------------------------------
# Basic attack (returns base damage BEFORE elemental/row multipliers)
# ------------------------------------------------------------------------------
func perform_basic_attack(target: BattleActor) -> int:
	# Base from STR + weapon dice (if any)
	var base: int = RPGRules.atk_damage(data)
	if data.weapon != null and data.weapon.dice != "":
		base += RPGRules.roll_dice(data.weapon.dice, rules)
	# Accuracy check vs target dodge (simple example)
	var acc: int = RPGRules.atk_accuracy(data)
	var dodge: int = RPGRules.atk_dodge(target.data)
	if acc < dodge:
		return 0
        return max(0, base)

func record_sigil_use(s: Sigil) -> void:
        if s == null:
                return
        var c: int = int(sigil_use_counts.get(s, 0))
        sigil_use_counts[s] = c + 1

# ------------------------------------------------------------------------------
# Damage & death
# ------------------------------------------------------------------------------
func apply_damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	var delta: int = max(0, amount)
	current_hp = max(0, current_hp - delta)
	_refresh_labels()
	emit_signal("hp_changed", self, current_hp)

	if current_hp <= 0:
		_refresh_labels()
		emit_signal("died", self)

func is_alive() -> bool:
	return current_hp > 0

# ------------------------------------------------------------------------------
# Visuals
# ------------------------------------------------------------------------------
func _build_labels() -> void:
	if _name_hp_label == null:
		_name_hp_label = Label.new()
		_name_hp_label.position = Vector2(-36, -36)
		add_child(_name_hp_label)

func _refresh_labels() -> void:
	if is_instance_valid(_name_hp_label):
		_name_hp_label.text = "%s  HP %d/%d" % [data.name, current_hp, max_hp]

func _draw() -> void:
	# Ally = circle, Enemy = square
	var r := 10.0
	if is_enemy:
		var rect := Rect2(Vector2(-r, -r), Vector2(2.0*r, 2.0*r))
		draw_rect(rect, Color(0.85, 0.15, 0.15), true, 2.0)
		draw_rect(rect, Color(0, 0, 0), false, 2.0)
	else:
		draw_circle(Vector2.ZERO, r, Color(0.1, 0.1, 0.12))
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0, 0, 0), 2.0)

# Force redraw after transforms
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()
