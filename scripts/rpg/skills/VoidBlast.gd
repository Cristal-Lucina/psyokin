# scripts/rpg/skills/VoidBlast.gd
# ------------------------------------------------------------------------------
# PSY-based single-target attack. Tagged as VOID for reactions.
# ------------------------------------------------------------------------------

extends Skill
class_name VoidBlast

func _init() -> void:
	id = &"void_blast"
	name = "Void Blast"

func perform(user: BattleActor, target: BattleActor) -> void:
	if user == null or target == null or not target.is_alive():
		return

	# Base PSY damage from user's effective Charm plus a touch of variance
	var base: int = RPGRules.psy_damage(user.data) + RPGRules.roll_dice("1d4")

	# Apply element + row logic consistently with basic attacks.
	var attack_type: int = RPGRules.AttackType.VOID
	var target_aff: Array[int] = (target.data.eff_affinities() if target.data.has_method("eff_affinities") else target.data.affinities)

	var elem_mult: float = RPGRules.reaction_multiplier(attack_type, target_aff)
	var row_off: float = RPGRules.row_offense_multiplier(user.row)
	var row_def: float = RPGRules.row_defense_multiplier(target.row)

	var final_dmg: int = max(0, int(round(float(base) * elem_mult * row_off * row_def)))
	if final_dmg > 0:
		target.apply_damage(final_dmg)
