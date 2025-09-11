# scripts/rpg/Armor.gd
# ------------------------------------------------------------------------------
# Body armor. Extends Resource for inspector export.
# ------------------------------------------------------------------------------

extends Resource
class_name Armor

@export var name: String = "Armor"
@export var armor_value: int = 0       # adds to physical defense
@export var armor_limit: int = 0       # subtracts from dodge/initiative
