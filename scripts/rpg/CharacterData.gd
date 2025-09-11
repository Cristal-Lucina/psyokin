extends Resource
class_name CharacterData

@export var name: String = "Unnamed"
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next: int = 10

@export var strength: int = 1
@export var sta: int = 1
@export var dex: int = 1
@export var intl: int = 1
@export var cha: int = 1

@export var affinities: Array[int] = []

# Keep gear exported as Resource so load order never breaks parsing.
@export var weapon: Resource   # Weapon
@export var armor: Resource    # Armor
@export var boots: Resource    # Boots
@export var bracelet: Resource # Bracelet

# ← IMPORTANT: skills are StringName identifiers
@export var skills: Array[StringName] = []

func refresh_xp_to_next() -> void:
	xp_to_next = 10 + level * 5

func add_xp(amount: int) -> int:
	var gained: int = 0
	xp += max(0, amount)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		gained += 1
		refresh_xp_to_next()
	return gained

static func _get_num(src: Object, prop: String) -> int:
	if src != null and src.has_method("get"):
		var v: Variant = src.get(prop)
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			return int(v)
	return 0

func _sum_sigils(stat_suffix: String) -> int:
	var total := 0
	if bracelet != null and bracelet.has_method("get"):
		total += _get_num(bracelet, "bonus_" + stat_suffix)
		var sigils_v: Variant = bracelet.get("sigils")
		if typeof(sigils_v) == TYPE_ARRAY:
			var arr: Array = sigils_v
			for s_v in arr:
				if s_v != null and (s_v as Object).has_method("get"):
					total += _get_num(s_v, "bonus_" + stat_suffix)
	return total

func eff_str() -> int: return strength + _sum_sigils("str")
func eff_sta() -> int: return sta       + _sum_sigils("sta")
func eff_dex() -> int: return dex       + _sum_sigils("dex")
func eff_int() -> int: return intl      + _sum_sigils("int")
func eff_cha() -> int: return cha       + _sum_sigils("cha")

func eff_affinities() -> Array[int]:
	var uniq := {}
	for a in affinities:
		uniq[a] = true
	if bracelet != null and bracelet.has_method("get"):
		var sigils_v: Variant = bracelet.get("sigils")
		if typeof(sigils_v) == TYPE_ARRAY:
			var arr: Array = sigils_v
			for s_v in arr:
				if s_v == null:
					continue
				var adds_v: Variant = (s_v as Object).get("add_affinities")
				if typeof(adds_v) == TYPE_ARRAY:
					var adds: Array = adds_v
					for a2 in adds:
						if typeof(a2) == TYPE_INT:
							uniq[int(a2)] = true
	var out: Array[int] = []
	for k in uniq.keys():
		out.append(int(k))
	return out

func total_armor_value() -> int:
	var v := 0
	if armor != null:
		v += _get_num(armor, "armor_value")
	if boots != null:
		v += _get_num(boots, "armor_value")
	return v

func total_armor_limit() -> int:
	var lim := 0
	if armor != null:
		lim += _get_num(armor, "armor_limit")
	if boots != null:
		lim += _get_num(boots, "armor_limit")
	return lim

func weapon_attack_type() -> int:
	if weapon != null and (weapon as Object).has_method("get"):
		var at: Variant = (weapon as Object).get("attack_type")
		if typeof(at) == TYPE_INT:
			return int(at)
	return RPGRules.AttackType.SLASH

func roll_weapon_damage(rules: RPGRules) -> int:
	if weapon == null or not (weapon as Object).has_method("get"):
		return 0
	var dice_v: Variant = (weapon as Object).get("dice")
	if typeof(dice_v) != TYPE_STRING:
		return 0
	var expr := String(dice_v)
	if expr == "":
		return 0
	return RPGRules.roll_dice(expr, rules)

func physical_damage(rolled: int) -> int:
	return RPGRules.atk_damage(self) + int(rolled)
