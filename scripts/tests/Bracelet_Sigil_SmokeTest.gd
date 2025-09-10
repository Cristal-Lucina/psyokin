# res://scripts/tests/Bracelet_Sigil_SmokeTest.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Verifies Bracelet + Sigils combine correctly and add affinities.
# HOW:
#   Attach to a Node scene and run with F6.
# ------------------------------------------------------------------------------

extends Node

func _ready() -> void:
	var rules: RPGRules = RPGRules.new()

	# Build two sigils
	var wind: Sigil = Sigil.new()
	wind.name = "Wind Sigil"
	wind.bonus_dex = 1
	wind.add_affinities = [RPGRules.AttackType.AIR]

	var focus: Sigil = Sigil.new()
	focus.name = "Focus Sigil"
	focus.bonus_int = 1
	focus.bonus_cha = 1

	# Bracelet with 2 slots and one small base bonus
	var br: Bracelet = Bracelet.new()
	br.name = "Bronze Bracelet"
	br.slot_count = 2
	br.bonus_sta = 1
	br.sigils = [wind, focus]

	# Simple gear
	var katana: Weapon = Weapon.new()
	katana.name = "Katana"
	katana.dice = "1d6+4"
	katana.weapon_limit = 1
	katana.attack_type = RPGRules.AttackType.SLASH

	var gi: Armor = Armor.new()
	gi.name = "Training Gi"
	gi.armor_value = 1
	gi.armor_limit = 0

	var boots: Boots = Boots.new()
	boots.name = "Light Boots"
	boots.armor_value = 1
	boots.armor_limit = 0

	# Character
	var c: CharacterData = CharacterData.new()
	c.name = "Tester"
	c.level = 3
	c.strength = 6
	c.sta = 5
	c.dex = 5
	c.intl = 4
	c.cha = 4
	c.affinities = [RPGRules.AttackType.SLASH]
	c.weapon = katana
	c.armor = gi
	c.boots = boots
	c.bracelet = br

	# Prints
	print("--- Bracelet + Sigils ---")
	print("eff STR/STA/DEX/INT/CHA =",
		c.eff_str(), c.eff_sta(), c.eff_dex(), c.eff_int(), c.eff_cha())
	print("eff affinities =", c.eff_affinities())

	# Example damage with element multiplier against a FIRE/IMPACT defender
	var defender_aff: Array[int] = [RPGRules.AttackType.FIRE, RPGRules.AttackType.IMPACT]
	var wroll: int = c.roll_weapon_damage(rules)
	var base: int = c.physical_damage(wroll)
	# Use the alias 'type_multiplier' if present, otherwise reaction_multiplier.
	var type_mult: float = RPGRules.type_multiplier(c.weapon_attack_type(), defender_aff)
	var final: int = int(round(float(base) * type_mult))
	print("roll=", wroll, " base=", base, " type_mult=", type_mult, " final=", final)
