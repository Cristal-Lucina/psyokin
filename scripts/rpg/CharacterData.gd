# scripts/rpg/CharacterData.gd
# ------------------------------------------------------------------------------
# Character sheet data used by BattleActor and systems:
#  - Core stats and equipment
#  - Armor value / armor limit aggregators
#  - Effective stats (for initiative/capture, etc.)
#  - XP store + level-up handling (returns levels gained)
#  - Convenience wrappers: hp()/mp() that delegate to RPGRules
# Notes:
#  - This is a plain data container (RefCounted), not a Node.
#  - BattleActor handles current_hp/mp at runtime; this class provides max values.
# ------------------------------------------------------------------------------

extends RefCounted
class_name CharacterData

# --- Identity -----------------------------------------------------------------
var name: String = "Unknown"

# --- Progression --------------------------------------------------------------
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100   # refreshed via refresh_xp_to_next()

# --- Base stats ---------------------------------------------------------------
var strength: int = 5
var sta: int = 5
var dex: int = 5
var intl: int = 5
var cha: int = 5

# --- Affinities (for elemental reactions) -------------------------------------
# Example: [RPGRules.AttackType.SLASH]
var affinities: Array[int] = []

# --- Equipment (keep types loose if your item scripts aren't global classes) --
var weapon: Object = null     # expected fields: attack_type:int, weapon_limit:int, dice:String
var armor: Object = null      # expected fields: armor_value:int, armor_limit:int
var boots: Object = null      # expected fields: armor_value:int, armor_limit:int
var bracelet: Object = null   # expected fields: bonus_sta:int (and slot_count:int later)

# --- Constants ----------------------------------------------------------------
const MAX_LEVEL: int = 99     # soft cap; adjust to your design

# ------------------------------------------------------------------------------
# Aggregates / derived helpers
# ------------------------------------------------------------------------------
func total_armor_value() -> int:
	var val: int = 0
	if armor != null and armor.has_method("get"):
		val += int(armor.get("armor_value"))
	elif armor != null and "armor_value" in armor:
		val += int(armor.armor_value)
	if boots != null and boots.has_method("get"):
		val += int(boots.get("armor_value"))
	elif boots != null and "armor_value" in boots:
		val += int(boots.armor_value)
	return val

func total_armor_limit() -> int:
	var lim: int = 0
	if armor != null and armor.has_method("get"):
		lim += int(armor.get("armor_limit"))
	elif armor != null and "armor_limit" in armor:
		lim += int(armor.armor_limit)
	if boots != null and boots.has_method("get"):
		lim += int(boots.get("armor_limit"))
	elif boots != null and "armor_limit" in boots:
		lim += int(boots.armor_limit)
	return lim

# Effective stats (hook for equipment bonuses if/when you add them)
func eff_str() -> int:
	return strength

func eff_sta() -> int:
	var bonus: int = 0
	if bracelet != null:
		if bracelet.has_method("get"):
			bonus = int(bracelet.get("bonus_sta"))
		elif "bonus_sta" in bracelet:
			bonus = int(bracelet.bonus_sta)
	return sta + bonus

func eff_dex() -> int:
	return dex

func eff_int() -> int:
	return intl

func eff_cha() -> int:
	return cha

# Max resource helpers (wrappers so old call sites like data.hp(rules) still work)
func hp(_rules: RPGRules = null) -> int:
	# Uses base sta (bracelet bonus is not auto-applied by RPGRules);
	# if you want bracelet to affect max HP, pass a surrogate obj or adjust RPGRules.
	return RPGRules.hp(self, -1, _rules)

func mp(_rules: RPGRules = null) -> int:
	return RPGRules.mp(self, -1, _rules)

# ------------------------------------------------------------------------------
# XP / Leveling
# ------------------------------------------------------------------------------
func refresh_xp_to_next() -> void:
	# Prefer Progression.xp_to_next(level) if available in your project.
	# Fallback curve if Progression is not present.
	var next: int = 0
	# If you have class_name Progression in your project, we can call it directly:
	# (Your BattleScene already calls Progression.xp_multiplier, so this should exist.)
	next = Progression.xp_to_next(level)
	xp_to_next = max(1, next)

func add_xp(amount: int) -> int:
	# Adds XP, performs level ups, returns number of levels gained.
	if amount <= 0:
		return 0
	xp += amount
	var gained: int = 0

	# Ensure xp_to_next is valid
	if xp_to_next <= 0:
		refresh_xp_to_next()

	while xp >= xp_to_next and level < MAX_LEVEL:
		xp -= xp_to_next
		level += 1
		gained += 1
		refresh_xp_to_next()

	# If at cap, clamp xp within the current band
	if level >= MAX_LEVEL:
		level = MAX_LEVEL
		xp = min(xp, xp_to_next - 1)

	return gained
