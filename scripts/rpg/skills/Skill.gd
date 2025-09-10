# scripts/rpg/skills/Skill.gd
# ------------------------------------------------------------------------------
# Base resource for battle skills. Subclasses implement perform() to apply
# effects like damage, healing, or buffs.
# ------------------------------------------------------------------------------

extends Resource
class_name Skill

@export var id: StringName
@export var name: String = ""

func perform(user: BattleActor, target: BattleActor) -> void:
	pass
