# scripts/rpg/Boots.gd
# ------------------------------------------------------------------------------
# WHAT:   Boots Resource. Light armor slot with the same semantics as Armor.
# WHY:    Lets you tune defense vs. mobility separately from body armor.
# USE:    Assign to CharacterData.boots.
# ------------------------------------------------------------------------------

extends Resource
class_name Boots

@export var name: String = "Unnamed Boots"
@export var armor_value: int = 0
@export var armor_limit: int = 0
