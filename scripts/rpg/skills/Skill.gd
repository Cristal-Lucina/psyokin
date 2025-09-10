# scripts/rpg/skills/Skill.gd
# ------------------------------------------------------------------------------
# Base resource for battle skills. Subclasses implement perform() to apply
# effects like damage, healing, or buffs.
# ------------------------------------------------------------------------------

extends Resource
class_name Skill

@export var id: StringName
@export var name: String = ""

# Note: Underscore-prefixed params avoid UNUSED_PARAMETER warnings in the base.
# Subclasses should override and use the parameters normally.
func perform(_user: BattleActor, _target: BattleActor) -> void:
	pass
