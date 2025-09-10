# scripts/tests/Rules_SmokeTest.gd
# Purpose: sanity-check RPGRules functions.

extends Node

func _ready() -> void:
	var rules := RPGRules.new()

	# Dice tests
	print("--- Dice ---")
	print("avg 1d6+4 =", RPGRules.avg_dice("1d6+4"))
	print("roll 1d6+4 =", rules.roll_dice("1d6+4"))

	# XP multiplier tests
	print("--- XP ---")
	for enemy_lvl in [6,5,4,3,2,1,0]:
		print("player 3 vs enemy", enemy_lvl, "=>", RPGRules.xp_multiplier(3, enemy_lvl))

	# Derived stat tests (sample numbers)
	print("--- Derived ---")
	var hpv := RPGRules.hp(6, 5)
	var mpv := RPGRules.mp(5, 5)
	var init := RPGRules.initiative(6, 1, rules.roll_d20())
	print("HP=", hpv, " MP=", mpv, " init=", init)

	# Element/row multipliers
	print("--- Elements ---")
	var attack_type := RPGRules.AttackType.SLASH
	var defender_aff := [RPGRules.AttackType.IMPACT, RPGRules.AttackType.FIRE]
	print("type mult =", RPGRules.type_multiplier(attack_type, defender_aff))

	print("--- Row ---")
	print("phys front off =", RPGRules.row_offense_multiplier(true, RPGRules.Row.FRONT))
	print("phys back off  =", RPGRules.row_offense_multiplier(true, RPGRules.Row.BACK))
	print("phys front def =", RPGRules.row_defense_multiplier(true, RPGRules.Row.FRONT))
	print("phys back def  =", RPGRules.row_defense_multiplier(true, RPGRules.Row.BACK))
