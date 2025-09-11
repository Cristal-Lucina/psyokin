# scripts/rpg/Weapon.gd
# ------------------------------------------------------------------------------
# Simple weapon resource. Must extend Resource so it can be exported on other
# Resources (e.g., CharacterData).
# ------------------------------------------------------------------------------

extends Resource
class_name Weapon

@export var name: String = "Weapon"
@export var dice: String = ""          # e.g. "1d6+4" or empty for flat STR only
@export var weapon_limit: int = 0      # affects accuracy in your rules
@export var attack_type: int = RPGRules.AttackType.SLASH
