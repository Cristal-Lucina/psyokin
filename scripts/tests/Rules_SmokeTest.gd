# scripts/tests/Rules_SmokeTest.gd
# Purpose: sanity-check RPGRules functions (Godot 4.x safe)

extends Node

func _ready() -> void:
	var rules: RPGRules = RPGRules.new()

	# --- Dice tests ------------------------------------------------------------
	print("--- Dice ---")
	print("avg 1d6+4 =", RPGRules.avg_dice("1d6+4"))
	print("roll 1d6+4 =", RPGRules.roll_dice("1d6+4"))  # static call

	# --- XP multiplier tests ---------------------------------------------------
	print("--- XP ---")
	for enemy_lvl in [6, 5, 4, 3, 2, 1, 0]:
		var mult: float = Progression.xp_multiplier(3, int(enemy_lvl))
		print("player 3 vs enemy ", enemy_lvl, " => ", mult)

	# --- Derived stat tests (sample numbers) ----------------------------------
	print("--- Derived ---")
	var hpv: int = RPGRules.hp(6, 5)
	var mpv: int = RPGRules.mp(5, 5)
	var init_val: int = RPGRules.initiative(6, 1, rules.roll_d20())  # roll_d20 is instance method
	print("HP=", hpv, " MP=", mpv, " init=", init_val)

	# --- Element/row multipliers ----------------------------------------------
	print("--- Elements ---")
	var attack_type: int = RPGRules.AttackType.SLASH
	var defender_aff: Array[int] = [RPGRules.AttackType.IMPACT, RPGRules.AttackType.FIRE]
	var type_mult: float = RPGRules.reaction_multiplier(attack_type, defender_aff)
	print("type mult =", type_mult)

	print("--- Row ---")
	var off_front: float = RPGRules.row_offense_multiplier(RPGRules.Row.FRONT)
	var off_back: float  = RPGRules.row_offense_multiplier(RPGRules.Row.BACK)
	var def_front: float = RPGRules.row_defense_multiplier(RPGRules.Row.FRONT)
	var def_back: float  = RPGRules.row_defense_multiplier(RPGRules.Row.BACK)
	print("off front =", off_front, " | off back =", off_back)
	print("def front =", def_front, " | def back =", def_back)
