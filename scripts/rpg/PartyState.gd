# res://scripts/rpg/PartyState.gd
# Simple party autoload that guarantees a starter hero with a
# Basic Bracelet (1 slot) + Void Sigil that unlocks `void_blast`.

extends Node
class_name PartyState

var members: Array[CharacterData] = []

func ensure_seed(_rules: RPGRules) -> void:
	# If empty, create a starter character.
	if members == null or not (members is Array) or (members as Array).is_empty():
		var cd := CharacterData.new()
		cd.name = "Player"
		cd.level = 1
		cd.xp = 0
		cd.refresh_xp_to_next()
		cd.strength = 3
		cd.sta = 3
		cd.dex = 3
		cd.intl = 3
		cd.cha = 3
		cd.affinities = [RPGRules.AttackType.SLASH]

		# Starter weapon
		var w := Weapon.new()
		w.name = "Practice Blade"
		w.dice = "1d6"
		w.weapon_limit = 0
		w.attack_type = RPGRules.AttackType.SLASH
		cd.weapon = w

		# Basic bracelet with one slot + a Void Sigil that unlocks void_blast
		var br := Bracelet.new()
		br.name = "Basic Bracelet"
		br.slot_count = 1
		br.bonus_sta = 0

		var sig := Sigil.new()
		sig.name = "Void Sigil"
		sig.sigil_type = "void"
		sig.unlock_skill_ids = [StringName("void_blast")]

		# Attach the sigil
		br.sigils = [sig]
		cd.bracelet = br

		# Ensure the skill list exists and includes the L1 ability
		cd.skills = [StringName("weapon_focus"), StringName("void_blast")]

		members = [cd]

	# Ensure lead exists
	if members.is_empty():
		return
	var lead: CharacterData = members[0]

	# Guarantee a bracelet
	if lead.bracelet == null:
		var br2 := Bracelet.new()
		br2.name = "Basic Bracelet"
		br2.slot_count = 1
		br2.bonus_sta = 0
		lead.bracelet = br2

	# Make sure a Void Sigil is equipped
	var has_void := false
	var existing: Array = []
	if lead.bracelet.has_method("equipped_sigils"):
		existing = lead.bracelet.equipped_sigils()
	else:
		var any: Variant = lead.bracelet.get("sigils")
		if typeof(any) == TYPE_ARRAY:
			existing = any

	for s in existing:
		if s is Sigil and String(s.sigil_type) == "void":
			has_void = true
			break

	if not has_void:
		var vs := Sigil.new()
		vs.name = "Void Sigil"
		vs.sigil_type = "void"
		vs.unlock_skill_ids = [StringName("void_blast")]
		var sigs: Array = []
		var got: Variant = lead.bracelet.get("sigils")
		if typeof(got) == TYPE_ARRAY:
			sigs = got
		sigs.append(vs)
		lead.bracelet.set("sigils", sigs)

	# Ensure the hero actually has the skill in their list
	if lead.skills == null or not (lead.skills is Array):
		lead.skills = []
	if not lead.skills.has(StringName("void_blast")):
		lead.skills.append(StringName("void_blast"))
