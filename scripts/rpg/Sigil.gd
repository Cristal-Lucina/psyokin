# scripts/rpg/Sigil.gd
# ------------------------------------------------------------------------------
# A slot-able upgrade that sits in a Bracelet. Can add stat bonuses, affinities,
# and unlock skill ids. Gains XP and levels (very simple model here).
# ------------------------------------------------------------------------------

extends Resource
class_name Sigil

@export var name: String = "Sigil"
@export var sigil_type: String = ""             # optional flavor tag

# Per-stat bonuses (these are added to base stats while equipped)
@export var bonus_str: int = 0
@export var bonus_sta: int = 0
@export var bonus_dex: int = 0
@export var bonus_int: int = 0
@export var bonus_cha: int = 0

# Extra elemental/attack-type affinities (RPGRules.AttackType values)
@export var add_affinities: Array[int] = []

# Skills unlocked while equipped (StringName identifiers)
@export var unlock_skill_ids: Array[StringName] = []

# Very light XP/level model (you can replace this with your sigil growth rules)
@export var xp: int = 0
@export var level: int = 1

func gain_xp(amount: int) -> void:
	xp += max(0, amount)
	# Example: threshold = 10 * current_level
	while xp >= 10 * level:
		xp -= 10 * level
		level += 1
