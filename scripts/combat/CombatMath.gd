# res://scripts/combat/CombatMath.gd
# Deterministic, testable combat math with debug-friendly roll outputs.
class_name CombatMath

# Use preload so this is a true constant expression.
const CT := preload("res://scripts/combat/CombatTuning.gd")

static func _try_get(src: Variant, prop: String) -> Variant:
	# Supports both Objects (Nodes/Resources with properties) and Dictionaries.
	if src == null:
		return null
	if src is Dictionary:
		return (src as Dictionary).get(prop, null)
	if src is Object:
		return (src as Object).get(prop)
	return null

static func _dex(c: Variant) -> int:
	var v: Variant = _try_get(c, "dex")
	if v == null: v = _try_get(c, "DEX")
	return int(v if v != null else 0)

static func _str(c: Variant) -> int:
	var v: Variant = _try_get(c, "str")
	if v == null: v = _try_get(c, "strength")
	return int(v if v != null else 0)

static func _sta(c: Variant) -> int:
	var v: Variant = _try_get(c, "sta")
	if v == null: v = _try_get(c, "stamina")
	return int(v if v != null else 0)

static func _intl(c: Variant) -> int:
	var v: Variant = _try_get(c, "int")
	if v == null: v = _try_get(c, "intl")
	if v == null: v = _try_get(c, "intelligence")
	return int(v if v != null else 0)

# Chance to hit [0..1]
static func hit_chance(attacker: Variant, defender: Variant) -> float:
	var dex_diff: float = float(_dex(attacker) - _dex(defender))
	var chance: float = CT.BASE_HIT + dex_diff * CT.DEX_TO_HIT
	return clampf(chance, CT.MIN_HIT, CT.MAX_HIT)

# Chance to crit [0..1]
static func crit_chance(attacker: Variant, defender: Variant) -> float:
	var dex_diff: float = float(_dex(attacker) - _dex(defender))
	var chance: float = CT.BASE_CRIT + dex_diff * CT.DEX_TO_CRIT
	return clampf(chance, 0.0, 0.5)

# Performs a hit roll. Returns a dictionary describing the roll.
static func roll_hit(attacker: Variant, defender: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var chance: float = hit_chance(attacker, defender)
	var roll: float = rng.randf()
	return {
		"type": "HIT",
		"chance": chance,
		"roll": roll,
		"success": roll < chance,
		"att_dex": _dex(attacker),
		"def_dex": _dex(defender),
	}

# Performs a crit roll. Call only if hit succeeded.
static func roll_crit(attacker: Variant, defender: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var chance: float = crit_chance(attacker, defender)
	var roll: float = rng.randf()
	return {
		"type": "CRIT",
		"chance": chance,
		"roll": roll,
		"success": roll < chance,
	}

# Simple physical damage. Returns final damage and a breakdown.
static func damage_physical(attacker: Variant, defender: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var base_amt: int = CT.ATK_BASE + int(_str(attacker) * CT.STR_TO_ATK) - int(_sta(defender) * CT.STA_TO_DEF)
	base_amt = max(1, base_amt)
	var variance: int = rng.randi_range(-CT.DAMAGE_VAR, CT.DAMAGE_VAR)
	var final_amt: int = max(1, base_amt + variance)
	return {
		"type": "DMG",
		"model": "physical",
		"base": base_amt,
		"variance": variance,
		"final": final_amt,
	}

# Simple magical (e.g., Void/INT-based) damage.
static func damage_magical(attacker: Variant, defender: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var base_amt: int = CT.ATK_BASE + int(_intl(attacker) * CT.INT_TO_MATK) - int(_sta(defender) * CT.MDEF_FROM_STA)
	base_amt = max(1, base_amt)
	var variance: int = rng.randi_range(-CT.DAMAGE_VAR, CT.DAMAGE_VAR)
	var final_amt: int = max(1, base_amt + variance)
	return {
		"type": "DMG",
		"model": "magical",
		"base": base_amt,
		"variance": variance,
		"final": final_amt,
	}
