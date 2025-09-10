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

# Which mind type this sigil belongs to ("void", "fire", "buff", etc.)
# "ordinary" means it can be equipped by anyone.
@export var sigil_type: String = "ordinary"

# Progression ------------------------------
@export var level: int = 1
@export var xp: int = 0

const LEVEL_XP: Array[int] = [0, 0, 30, 100, 300]

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

func xp_to_next() -> int:
        if level >= LEVEL_XP.size() - 1:
                return 0
        return LEVEL_XP[level + 1]

func gain_xp(amount: int) -> void:
        if amount <= 0:
                return
        xp += amount
        while level < LEVEL_XP.size() - 1 and xp >= LEVEL_XP[level + 1]:
                level += 1

func compatible_with(mind_type: String) -> bool:
        if sigil_type == "ordinary":
                return true
        if mind_type.to_lower() == "omega":
                return true
        return sigil_type.to_lower() == mind_type.to_lower()
