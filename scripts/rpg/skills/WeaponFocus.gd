# scripts/rpg/skills/WeaponFocus.gd
# ------------------------------------------------------------------------------
# Simple offensive skill that deals weapon-based damage to a single target.
# ------------------------------------------------------------------------------

extends Skill
class_name WeaponFocus

func _init() -> void:
	id = StringName("weapon_focus")
	name = "Weapon Focus"

func perform(user: BattleActor, target: BattleActor) -> void:
	if user == null or target == null:
		return
	var base: int = user.perform_basic_attack(target)
	if base > 0:
		target.apply_damage(base)
