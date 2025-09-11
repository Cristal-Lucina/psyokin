# scripts/rpg/skills/VoidBlast.gd
# ------------------------------------------------------------------------------
# Simple magical attack granted by the starting Void Sigil.
# Deals INT-based damage to a single target.
# ------------------------------------------------------------------------------

extends Skill
class_name VoidBlast

func _init() -> void:
	id = StringName("void_blast")
	name = "Void Blast"

func perform(user: BattleActor, target: BattleActor) -> void:
	if user == null or target == null:
		return
	var dmg: int = 4 + user.data.eff_int()
	target.apply_damage(dmg)
	if user.data.bracelet != null:
		for s in user.data.bracelet.equipped_sigils():
			if s.unlock_skill_ids.has(StringName("void_blast")):
				user.record_sigil_use(s)
				break
