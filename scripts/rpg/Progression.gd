# scripts/rpg/Progression.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Progression math used across systems.
#   - xp_multiplier(): matches your EXP scaling table
#   - capture_chance(): tunable capture formula
# NOTES:
#   All locals are explicitly typed to avoid Variant inference warnings.
# ------------------------------------------------------------------------------

extends RefCounted
class_name Progression

# EXP multiplier table (your rules)
static func xp_multiplier(attacker_level: int, enemy_level: int) -> float:
	var diff: int = attacker_level - enemy_level
	if diff <= 0: return 1.0
	elif diff <= 2: return 0.80
	elif diff <= 4: return 0.60
	elif diff <= 6: return 0.40
	elif diff <= 8: return 0.20
	else: return 0.01

# XP curve: simple, readable, easy to tune
static func xp_to_next(level: int) -> int:
	# Level 1 -> 100, then +50 per level (cap at 99 to be safe)
	return 100 + max(0, level - 1) * 50

# Capture chance (unchanged; typed to avoid Variant)
static func capture_chance(attacker_cha: int, enemy_level: int, hp_ratio: float, item_rate: float) -> float:
	var cha_bonus: float = clamp((float(attacker_cha) - 5.0) * 0.03, -0.15, 0.30)
	var low_hp_bonus: float = clamp((1.0 - hp_ratio) * 0.50, 0.0, 0.50)
	var level_penalty: float = clamp((float(enemy_level) - 3.0) * 0.02, 0.0, 0.25)
	var p: float = item_rate + cha_bonus + low_hp_bonus - level_penalty
	return clamp(p, 0.05, 0.95)
