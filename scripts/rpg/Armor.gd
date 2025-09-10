# scripts/rpg/Armor.gd
# ------------------------------------------------------------------------------
# WHAT:   Armor Resource. Adds defense and may reduce mobility via armor_limit.
# WHY:    Splits protection (armor_value) from encumbrance (armor_limit).
# USE:    Assign to CharacterData.armor.
# ------------------------------------------------------------------------------

extends Resource
class_name Armor

@export var name: String = "Unnamed Armor"
@export var armor_value: int = 0   # Adds to attack defense
@export var armor_limit: int = 0   # Subtracted from dex for dodge/initiative
