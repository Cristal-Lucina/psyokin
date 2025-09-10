# scripts/rpg/Bracelet.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Bracelet Resource with socket slots for Sigils.
#   - Base stat bonuses on the bracelet
#   - Configurable number of slots
#   - Holds a list of Sigils (first slot_count entries are active)
# WHY:
#   Replaces "charm" and avoids any FF terminology.
# ------------------------------------------------------------------------------

extends Resource
class_name Bracelet

@export var name: String = "Bracelet"

# Base stat bonuses from the bracelet itself
@export var bonus_str: int = 0
@export var bonus_sta: int = 0
@export var bonus_dex: int = 0
@export var bonus_int: int = 0
@export var bonus_cha: int = 0

# Number of usable slots on this bracelet
@export_range(0, 6, 1) var slot_count: int = 1

# Socketed Sigils (editor-friendly untyped array; can be Array[Sigil] later)
@export var sigils: Array = []

func equipped_sigils() -> Array:
	# Returns only the active sigils (up to slot_count), skipping nulls.
	var out: Array = []
	for i in min(slot_count, sigils.size()):
		var s = sigils[i]
		if s != null:
			out.append(s)
	return out

func total_bonuses() -> Dictionary:
	# Sum bracelet base bonuses + all active sigil bonuses.
	var t := {
		"str": bonus_str,
		"sta": bonus_sta,
		"dex": bonus_dex,
		"int": bonus_int,
		"cha": bonus_cha
	}
	for s in equipped_sigils():
		t["str"] += s.bonus_str
		t["sta"] += s.bonus_sta
		t["dex"] += s.bonus_dex
		t["int"] += s.bonus_int
		t["cha"] += s.bonus_cha
	return t

func added_affinities() -> Array[int]:
	# Aggregates affinity additions from active sigils (deduplicated).
	var out: Array[int] = []
	for s in equipped_sigils():
		for a in s.add_affinities:
			if a not in out:
				out.append(a)
	return out

# Optional helpers for code-driven socketing
func add_sigil(s: Sigil, mind_type: String = "OMEGA") -> bool:

	if sigils.size() >= slot_count:
		return false
	if s == null:
		return false
	if not s.compatible_with(mind_type):
		return false
	sigils.append(s)
	return true


func remove_sigil(s: Sigil) -> bool:
	var idx := sigils.find(s)
	if idx == -1:
		return false
	sigils.remove_at(idx)
	return true
