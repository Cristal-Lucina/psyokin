# res://scripts/rpg/SkillsDB.gd
# -----------------------------------------------------------------------------
# Central unlock table for battle skills by STAT level.
# Query with:
#   SkillsDB.get_unlocked("str", level) -> Array[String] of internal skill ids
# Valid stat slugs: "str","sta","dex","intl","cha"
# -----------------------------------------------------------------------------

extends Node
class_name SkillsDB

# Strength line
const STR_UNLOCKS = {
	2: ["weapon_focus"],
	4: ["trip_capture_boost"],
	6: ["atk_crit_focus"],
	8: ["grapple_lock_group_capture"],
	10: ["perfect_atk_plus50"],
	11: ["meteor_clash_ultimate"]
}

# Stamina line
const STA_UNLOCKS = {
	2: ["use_medium_armor"],
	4: ["shield_plus_80pct_1t"],
	6: ["use_heavy_armor"],
	8: ["hp_plus_50pct"],
	10: ["team_barrier_1t"],
	11: ["no_party_damage_2t_once"]
}

# Dexterity line
const DEX_UNLOCKS = {
	2: ["first_to_fight_initiative"],
	4: ["dodge_up"],
	6: ["armor_accuracy_no_penalty"],
	8: ["warp_neck_strike_high_crit_vulnerable"],
	10: ["double_strike_half_second"],
	11: ["omni_strike_all_double_high_crit"]
}

# Intelligence line
const INTL_UNLOCKS = {
	2: ["healing_plus"],
	4: ["sigil_training_plus_double_xp"],
	6: ["mana_absorb"],
	8: ["mana_plus_50pct"],
	10: ["team_mana_recovery"],
	11: ["mass_confusion_2t"]
}

# Charm line
const CHA_UNLOCKS = {
	2: ["psy_attack_focus"],
	4: ["charm_chat_capture_boost"],
	6: ["psy_crit_focus"],
	8: ["mind_trap_group_capture"],
	10: ["perfect_psy_plus50"],
	11: ["mind_collapse_ultimate"]
}

# Return all unlocked skill ids at or below 'level' for the given stat slug.
static func get_unlocked(stat_slug: String, level: int) -> Array[String]:
	var table: Dictionary = {}
	match stat_slug:
		"str": table = STR_UNLOCKS
		"sta": table = STA_UNLOCKS
		"dex": table = DEX_UNLOCKS
		"intl": table = INTL_UNLOCKS
		"cha": table = CHA_UNLOCKS
		_: table = {}

	var out: Array[String] = []
	var keys: Array = table.keys()
	for k in keys:
		var req: int = int(k)
		if level >= req:
			var arr_any: Variant = table[k]
			if typeof(arr_any) == TYPE_ARRAY:
				var arr: Array = arr_any
				for s_any in arr:
					out.append(String(s_any))
	return out
