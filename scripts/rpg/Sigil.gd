# scripts/rpg/Sigil.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Sigil Resource you socket into a Bracelet.
#   Provides flat stat bonuses and can add elemental affinities.
# WHY:
#   Lets Bracelets grant configurable bonuses without using any trademarked terms.
# ------------------------------------------------------------------------------

extends Resource
class_name Sigil

@export var name: String = "Sigil"

# Flat stat bonuses while the sigil is socketed
@export var bonus_str: int = 0
@export var bonus_sta: int = 0
@export var bonus_dex: int = 0
@export var bonus_int: int = 0
@export var bonus_cha: int = 0

# Optional: add attack/element affinities (values from RPGRules.AttackType)
@export var add_affinities: Array[int] = []

# Placeholder for future expansion: skill unlocks granted by this sigil
@export var unlock_skill_ids: Array[StringName] = []
