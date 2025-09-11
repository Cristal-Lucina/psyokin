# scripts/rpg/skills/Skill.gd
# ------------------------------------------------------------------------------
# Base Skill resource. Subclasses override perform().
# ------------------------------------------------------------------------------

extends Resource
class_name Skill

@export var id: StringName
@export var name: String = ""

func perform(_user: BattleActor, _target: BattleActor) -> void:
	# Override in concrete skills; return value not required.
	pass
