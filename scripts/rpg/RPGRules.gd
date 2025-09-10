# scripts/rpg/RPGRules.gd
# ------------------------------------------------------------------------------
# Core battle rules utilities
# ------------------------------------------------------------------------------

extends RefCounted
class_name RPGRules

# ------------------------------------------------------------------------------
# Locate BalanceTuning (autoload or scene)
# ------------------------------------------------------------------------------
static func _find_tuning_node() -> Object:
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	var tree: SceneTree = loop as SceneTree
	if tree == null or tree.root == null:
		return null

	# Preferred: Autoload named "BalanceTuning"
	var n := tree.root.get_node_or_null("BalanceTuning")
	if n != null:
		return n

	# Fallback: any descendant named "BalanceTuning"
	return tree.root.find_child("BalanceTuning", true, false)

static func _tune_int(node: Object, prop: String, def: int) -> int:
	if node != null and node.has_method("get"):
		var v: Variant = node.get(prop)
		if typeof(v) == TYPE_INT:
			return int(v)
		if typeof(v) == TYPE_FLOAT:
			return int(v)
	return def

static func _tune_float(node: Object, prop: String, def: float) -> float:
	if node != null and node.has_method("get"):
		var v: Variant = node.get(prop)
		if typeof(v) == TYPE_FLOAT:
			return float(v)
		if typeof(v) == TYPE_INT:
			return float(v)
	return def

# ------------------------------------------------------------------------------
# Defaults if BalanceTuning is missing
# ------------------------------------------------------------------------------
const DEF_HP_BASE_ALLY:    int   = 16
const DEF_HP_PER_STA_ALLY: int   = 3
const DEF_HP_LVL_SCALE_ALLY: float = 0.75

const DEF_HP_BASE_ENEMY:    int   = 10
const DEF_HP_PER_STA_ENEMY: int   = 2
const DEF_HP_LVL_SCALE_ENEMY: float = 0.50

# Read-only legacy aliases (kept for compatibility)
const HP_BASE: int = DEF_HP_BASE_ALLY
const HP_PER_STA: int = DEF_HP_PER_STA_ALLY
const HP_LVL_SCALE: float = DEF_HP_LVL_SCALE_ALLY

# Side / faction
enum Side { ALLY = 0, ENEMY = 1 }

# ------------------------------------------------------------------------------
# Enums
# ------------------------------------------------------------------------------
enum AttackType {
	SLASH = 0, PIERCE = 1, IMPACT = 2,
	FIRE  = 3, WATER  = 4, AIR    = 5, EARTH = 6,
	VOID  = 7, DATA   = 8,
}

enum Row { FRONT = 0, BACK = 1 }

# ------------------------------------------------------------------------------
# RNG + Initiative
# ------------------------------------------------------------------------------
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func roll_d20() -> int:
	return _rng.randi_range(1, 20)

func roll_float() -> float:
	return _rng.randf()

static func initiative(eff_dex: int, armor_limit: int, d20_roll: int) -> int:
	return eff_dex - armor_limit + d20_roll

# ------------------------------------------------------------------------------
# Derived stat helpers
# ------------------------------------------------------------------------------
# HP from BalanceTuning sliders (if present). Expected properties on
# BalanceTuning:
#   HP_BASE_ALLY,    HP_PER_STA_ALLY,    HP_LVL_SCALE_ALLY
#   HP_BASE_ENEMY,   HP_PER_STA_ENEMY,   HP_LVL_SCALE_ENEMY
static func hp_from_stats(sta_level: int, level: int, side: int = Side.ALLY) -> int:
	var t: Object = _find_tuning_node()

	var base_hp: int
	var per_sta: int
	var lvl_scale: float

	if side == Side.ENEMY:
		base_hp   = _tune_int(t,   "HP_BASE_ENEMY",    DEF_HP_BASE_ENEMY)
		per_sta   = _tune_int(t,   "HP_PER_STA_ENEMY", DEF_HP_PER_STA_ENEMY)
		lvl_scale = _tune_float(t, "HP_LVL_SCALE_ENEMY", DEF_HP_LVL_SCALE_ENEMY)
	else:
		base_hp   = _tune_int(t,   "HP_BASE_ALLY",    DEF_HP_BASE_ALLY)
		per_sta   = _tune_int(t,   "HP_PER_STA_ALLY", DEF_HP_PER_STA_ALLY)
		lvl_scale = _tune_float(t, "HP_LVL_SCALE_ALLY", DEF_HP_LVL_SCALE_ALLY)

	var from_sta: int = sta_level * per_sta
	var from_lvl: int = int(level * lvl_scale) * sta_level
	var total_hp: int = base_hp + from_sta + from_lvl
	return max(1, total_hp)

# Optional mirror helper
static func hp_tuned(sta_level: int, level: int, side: int = Side.ALLY) -> int:
	return hp_from_stats(sta_level, level, side)

# Legacy wrapper: accepts Object or raw numbers (sta, level).
# The 3rd parameter remains for compatibility; an optional 4th "side".
static func hp(subject_or_sta: Variant, level: int = -1, _rules: RPGRules = null, side: int = Side.ALLY) -> int:
	var sta: int
	var lvl: int
	if typeof(subject_or_sta) == TYPE_OBJECT:
		var obj: Object = subject_or_sta
		sta = int(obj.get("sta"))
		lvl = int(obj.get("level"))
	else:
		sta = int(subject_or_sta)
		lvl = (level if level >= 0 else 1)
	return hp_from_stats(sta, lvl, side)

static func mp(subject_or_int: Variant, level: int = -1, _rules: RPGRules = null) -> int:
	var intl: int
	var lvl: int
	if typeof(subject_or_int) == TYPE_OBJECT:
		var obj: Object = subject_or_int
		intl = int(obj.get("intl"))
		lvl  = int(obj.get("level"))
	else:
		intl = int(subject_or_int)
		lvl  = level if level >= 0 else 1
	return intl + int(floor((float(lvl) / 2.0) * float(intl)))

static func atk_def(subject_or_sta: Variant, armor_value: int = 0, _rules: RPGRules = null) -> int:
	if typeof(subject_or_sta) == TYPE_OBJECT:
		var subject: Object = subject_or_sta
		var sta: int = int(subject.get("sta"))
		var arm_val: int = 0
		if subject.has_method("total_armor_value"):
			arm_val = int(subject.call("total_armor_value"))
		else:
			var ar: Object = subject.get("armor")
			var bt: Object = subject.get("boots")
			if ar != null:
				arm_val += int(ar.get("armor_value"))
			if bt != null:
				arm_val += int(bt.get("armor_value"))
		return sta + arm_val
	return int(subject_or_sta) + int(armor_value)

static func atk_dodge(subject_or_dex: Variant, armor_limit: int = 0, _rules: RPGRules = null) -> int:
	if typeof(subject_or_dex) == TYPE_OBJECT:
		var subject: Object = subject_or_dex
		var dex: int = int(subject.get("dex"))
		var limit: int = 0
		if subject.has_method("total_armor_limit"):
			limit = int(subject.call("total_armor_limit"))
		else:
			var ar: Object = subject.get("armor")
			var bt: Object = subject.get("boots")
			if ar != null:
				limit += int(ar.get("armor_limit"))
			if bt != null:
				limit += int(bt.get("armor_limit"))
		return dex - limit
	return int(subject_or_dex) - int(armor_limit)

static func psy_dodge(subject_or_dex: Variant, armor_limit: int = 0, _rules: RPGRules = null) -> int:
	return atk_dodge(subject_or_dex, armor_limit, _rules)

static func atk_accuracy(subject_or_str: Variant, weapon_limit: int = -1, d20_roll: int = 0, _rules: RPGRules = null) -> int:
	var str_val: int
	var wlim: int
	if typeof(subject_or_str) == TYPE_OBJECT:
		var obj: Object = subject_or_str
		str_val = int(obj.get("strength"))
		var wpn: Variant = obj.get("weapon")
		if wpn != null and wpn is Object:
			wlim = int(wpn.get("weapon_limit"))
		else:
			wlim = 0
	else:
		str_val = int(subject_or_str)
		wlim = weapon_limit if weapon_limit >= 0 else 0
	return str_val + wlim + d20_roll

static func psy_accuracy(subject_or_cha: Variant, weapon_limit: int = -1, d20_roll: int = 0, _rules: RPGRules = null) -> int:
	var cha_val: int
	var wlim: int
	if typeof(subject_or_cha) == TYPE_OBJECT:
		var obj: Object = subject_or_cha
		cha_val = int(obj.get("cha"))
		var wpn: Variant = obj.get("weapon")
		if wpn != null and wpn is Object:
			wlim = int(wpn.get("weapon_limit"))
		else:
			wlim = 0
	else:
		cha_val = int(subject_or_cha)
		wlim = weapon_limit if weapon_limit >= 0 else 0
	return cha_val + wlim + d20_roll

static func atk_damage(subject_or_str: Variant, _unused: Variant = null) -> int:
	if typeof(subject_or_str) == TYPE_OBJECT:
		var obj: Object = subject_or_str
		return int(obj.get("strength"))
	return int(subject_or_str)

static func psy_damage(subject_or_cha: Variant, _unused: Variant = null) -> int:
	if typeof(subject_or_cha) == TYPE_OBJECT:
		var obj: Object = subject_or_cha
		return int(obj.get("cha"))
	return int(subject_or_cha)

# ------------------------------------------------------------------------------
# Element weakness/resistance
# ------------------------------------------------------------------------------
const WEAK_MULT: float  = 1.5
const RESIST_MULT: float = 0.5

static func weakness_of(t: int) -> int:
	match t:
		AttackType.SLASH:  return AttackType.PIERCE
		AttackType.PIERCE: return AttackType.IMPACT
		AttackType.IMPACT: return AttackType.SLASH
		AttackType.FIRE:   return AttackType.WATER
		AttackType.WATER:  return AttackType.EARTH
		AttackType.EARTH:  return AttackType.AIR
		AttackType.AIR:    return AttackType.FIRE
		AttackType.VOID:   return AttackType.DATA
		AttackType.DATA:   return AttackType.VOID
		_:                 return t

static func reaction_multiplier(attack_type: int, target_affinities: Array[int]) -> float:
	var mult: float = 1.0
	for a in target_affinities:
		if attack_type == a:
			mult *= RESIST_MULT
		elif attack_type == weakness_of(a):
			mult *= WEAK_MULT
	return clamp(mult, 0.25, 2.25)

# --- alias for older call sites/tests ---
static func type_multiplier(attack_type: int, target_affinities: Array[int]) -> float:
	return reaction_multiplier(attack_type, target_affinities)

static func reaction_tag(mult: float) -> String:
	if mult > 1.01:
		return "WEAK"
	if mult < 0.99:
		return "RESIST"
	return ""


# ------------------------------------------------------------------------------
# Dice helpers
# ------------------------------------------------------------------------------
static func parse_dice(expr: String) -> Dictionary:
	var s: String = expr.strip_edges().to_lower()
	var n: int = 0
	var sides: int = 0
	var bonus: int = 0

	if s == "":
		return {"n": 0, "s": 0, "b": 0}

	if "d" not in s:
		bonus = int(s)
		return {"n": 0, "s": 0, "b": bonus}

	var parts: PackedStringArray = s.split("d", false, 2)
	var left: String = parts[0]  # may be "" meaning 1
	var right: String = ""
	if parts.size() > 1:
		right = parts[1]

	if left == "":
		n = 1
	else:
		n = int(left)

	var cut: int = -1
	var bonus_sign: int = +1
	var p_plus: int = right.find("+")
	var p_minus: int = right.find("-")

	if p_plus > 0 and p_minus > 0:
		cut = min(p_plus, p_minus)
		bonus_sign = -1 if cut == p_minus else +1
	elif p_plus > 0:
		cut = p_plus
		bonus_sign = +1
	elif p_minus > 0:
		cut = p_minus
		bonus_sign = -1

	if cut > 0:
		var s_sides: String = right.substr(0, cut)
		var s_bonus: String = right.substr(cut + 1)
		sides = int(s_sides)
		bonus = bonus_sign * int(s_bonus)
	else:
		sides = int(right)

	return {"n": max(0, n), "s": max(0, sides), "b": bonus}

static func avg_dice(expr: String) -> int:
	var d: Dictionary = parse_dice(expr)
	var n: int = int(d["n"])
	var s: int = int(d["s"])
	var b: int = int(d["b"])
	if n == 0 and s == 0:
		return b
	if s <= 0:
		return b
	var avg: float = float(n) * (float(s) + 1.0) * 0.5 + float(b)
	return int(round(avg))

static func roll_dice(expr: String, _rules: RPGRules = null) -> int:
	var d: Dictionary = parse_dice(expr)
	var n: int = int(d["n"])
	var s: int = int(d["s"])
	var b: int = int(d["b"])

	if n == 0 and s == 0:
		return b

	var rng: RandomNumberGenerator
	if _rules != null:
		rng = _rules._rng
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var total: int = 0
	if s > 0 and n > 0:
		for _i in n:
			total += rng.randi_range(1, s)
	total += b
	return total

# Legacy aliases
static func roll(expr: String, _rules: RPGRules = null) -> int:
	return roll_dice(expr, _rules)

static func roll_dice_expr(expr: String, _rules: RPGRules = null) -> int:
	return roll_dice(expr, _rules)

# ------------------------------------------------------------------------------
# Row offense/defense multipliers
# ------------------------------------------------------------------------------
const FRONT_OFFENSE_MULT: float = 1.10
const BACK_OFFENSE_MULT:  float = 0.90
const FRONT_DEFENSE_MULT: float = 1.10
const BACK_DEFENSE_MULT:  float = 0.90

static func row_offense_multiplier(row: int) -> float:
	return FRONT_OFFENSE_MULT if row == Row.FRONT else BACK_OFFENSE_MULT

static func row_defense_multiplier(row: int) -> float:
	return FRONT_DEFENSE_MULT if row == Row.FRONT else BACK_DEFENSE_MULT
