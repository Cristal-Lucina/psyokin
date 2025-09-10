# res://scripts/rpg/PlayerProfile.gd
# -----------------------------------------------------------------------------
# PlayerProfile is a temporary builder used on the start screen to capture
# identity + starting stat allocation. It enforces your point costs and caps.
# After confirmation, you'll convert it to a CharacterData for gameplay.
# -----------------------------------------------------------------------------

extends RefCounted
class_name PlayerProfile

# We keep pronoun selections simple for now; "ANY" will lock at creation time
# to one of HE/SHE/THEY (random) so downstream text systems have a concrete value.
enum Pronoun { HE, SHE, THEY, ANY }

# Stat identifiers to avoid stringly-typed code.
enum Stat { STR, STA, DEX, INTL, CHA }

# --- Identity -----------------------------------------------------------------
var name: String = "Player"
var pronoun_choice: Pronoun = Pronoun.ANY
var pronoun_final: Pronoun = Pronoun.THEY   # resolved from pronoun_choice at confirm time
var body_type: String = "Average"           # free-form for now; hook to your art later
var genital_type: String = "none"           # "penis", "vagina", "none"

# --- Allocation rules ----------------------------------------------------------
# Budget available at creation time.
const START_BUDGET: int = 30

# You can raise each stat to at most this level at creation.
const CREATION_MAX_LEVEL: int = 10

# Per-level costs for raising a stat from level N to N+1.
# Index 1 = cost to go 1->2, index 10 = cost to go 10->11 (we gate 11 elsewhere).
# Level 0 unused; we start at level 1 baseline for every stat.
const COST_BY_LEVEL: Array[int] = [0, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7]

# --- Current levels at creation (baseline 1 each) ------------------------------
var level_str: int = 1
var level_sta: int = 1
var level_dex: int = 1
var level_intl: int = 1
var level_cha: int = 1

# Internal: current remaining points from START_BUDGET after allocations.
var remaining: int = START_BUDGET

# ------------------------------------------------------------------------------

static func stat_to_name(s: Stat) -> String:
	match s:
		Stat.STR: return "Strength"
		Stat.STA: return "Stamina"
		Stat.DEX: return "Dexterity"
		Stat.INTL: return "Intelligence"
		Stat.CHA: return "Charm"
		_: return "?"

func _get_level_ref(s: Stat) -> int:
	match s:
		Stat.STR: return level_str
		Stat.STA: return level_sta
		Stat.DEX: return level_dex
		Stat.INTL: return level_intl
		Stat.CHA: return level_cha
		_: return 1

func _set_level_ref(s: Stat, v: int) -> void:
	match s:
		Stat.STR: level_str = v
		Stat.STA: level_sta = v
		Stat.DEX: level_dex = v
		Stat.INTL: level_intl = v
		Stat.CHA: level_cha = v
		_: pass

# Cost to raise the given stat by one level from its current level.
func next_cost(s: Stat) -> int:
	var cur: int = _get_level_ref(s)
	cur = clamp(cur, 1, COST_BY_LEVEL.size() - 1)
	return COST_BY_LEVEL[cur]

# Whether we can increase this stat right now under budget + creation caps.
func can_increase(s: Stat) -> bool:
	var cur: int = _get_level_ref(s)
	if cur >= CREATION_MAX_LEVEL:
		return false
	var cost: int = next_cost(s)
	return remaining >= cost

# Apply a +1 to a given stat, reducing remaining budget accordingly.
func increase(s: Stat) -> bool:
	if not can_increase(s):
		return false
	var cur: int = _get_level_ref(s)
	var cost: int = next_cost(s)
	_set_level_ref(s, cur + 1)
	remaining -= cost
	return true

# You may allow lowering back to the baseline 1 to fix misclicks.
# We refund the cost that was originally paid to raise from (new_level) to (new_level+1).
func can_decrease(s: Stat) -> bool:
	var cur: int = _get_level_ref(s)
	return cur > 1

func decrease(s: Stat) -> bool:
	if not can_decrease(s):
		return false
	var cur: int = _get_level_ref(s)
	# The cost to remove is the cost that was paid to reach 'cur' (i.e., cost at level cur-1).
	var refund_level: int = max(1, cur - 1)
	var refund_cost: int = COST_BY_LEVEL[refund_level]
	_set_level_ref(s, cur - 1)
	remaining += refund_cost
	return true

# Lock pronoun_final from pronoun_choice.
func finalize_pronoun(rng: RandomNumberGenerator) -> void:
	match pronoun_choice:
		Pronoun.HE, Pronoun.SHE, Pronoun.THEY:
			pronoun_final = pronoun_choice
		Pronoun.ANY:
			var pool: Array[Pronoun] = [Pronoun.HE, Pronoun.SHE, Pronoun.THEY]
			rng.randomize()
			var pick: int = rng.randi_range(0, pool.size() - 1)
			pronoun_final = pool[pick]
		_:
			pronoun_final = Pronoun.THEY
