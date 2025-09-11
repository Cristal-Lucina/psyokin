# scripts/rpg/skills/SkillLibrary.gd
# ------------------------------------------------------------------------------
# Factory to instantiate skills by ID.
# ------------------------------------------------------------------------------

extends Node
class_name SkillLibrary

static func create(id: String) -> Skill:
	match id:
		"void_blast":
			var s: VoidBlast = VoidBlast.new()
			return s
		_:
			return null
