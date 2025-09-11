# scripts/rpg/SkillLibrary.gd
# ------------------------------------------------------------------------------
# Factory for creating Skill resources by id.
# ------------------------------------------------------------------------------

extends Node
class_name SkillLibrary

static var _cache: Dictionary = {
	"weapon_focus": preload("res://scripts/rpg/skills/WeaponFocus.gd"),
	"void_blast": preload("res://scripts/rpg/skills/VoidBlast.gd"),
}

static func create(id: String) -> Skill:
	var script: Variant = _cache.get(id)
	if script == null:
		return null
	return (script as Script).new()
