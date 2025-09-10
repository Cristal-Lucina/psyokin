# scripts/rpg/Weapon.gd
extends RefCounted
class_name Weapon

var name: String = "Unnamed"
var dice: String = "1d4"                         # e.g. "1d6+4"
var weapon_limit: int = 0                        # adds to accuracy checks
var attack_type: int = RPGRules.AttackType.SLASH

func avg_damage() -> int:
	return RPGRules.avg_dice(dice)

func roll_damage(rules: RPGRules = null) -> int:
	return RPGRules.roll_dice(dice, rules)
