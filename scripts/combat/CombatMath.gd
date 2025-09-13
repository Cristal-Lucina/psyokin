# res://scripts/combat/CombatMath.gd
extends RefCounted
class_name CombatMath

enum Channel { NEUTRAL, BRAWN, MIND }

const BASE_ACC: float = 0.80
const HIT_MIN: float = 0.05
const HIT_MAX: float = 0.95

const WPN_CHN_ON_DMG_MULT: float = 1.10
const WPN_CHN_OFF_DMG_MULT: float = 0.90
const WPN_CHN_ON_ACC_BONUS: int = 5
const WPN_CHN_OFF_ACC_BONUS: int = -5

const ARM_CHN_ON_EVA_BONUS: int = 5
const ARM_CHN_OFF_EVA_BONUS: int = -5

static func brw(cd: CharacterData) -> int: return cd.strength
static func mnd(cd: CharacterData) -> int: return cd.cha
static func vtl(cd: CharacterData) -> int: return cd.sta
static func fcs(cd: CharacterData) -> int: return cd.intl
static func tpo(cd: CharacterData) -> int: return cd.dex

static func level_quarter(level: int) -> int:
	return maxi(1, int(ceil(float(level) / 4.0)))

static func level_half(level: int) -> int:
	return maxi(1, int(ceil(float(level) / 2.0)))

static func _get_i(obj: Object, prop: String) -> int:
	if obj == null or not obj.has_method("get"):
		return 0
	var v: Variant = obj.get(prop)
	return int(v) if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) else 0

static func _get_s(obj: Object, prop: String) -> String:
	if obj == null or not obj.has_method("get"):
		return ""
	var v: Variant = obj.get(prop)
	return String(v) if typeof(v) == TYPE_STRING else ""

static func weapon_atk_dmg(w: Weapon) -> int:
	var val: int = _get_i(w, "atk_dmg")
	return val if val > 0 else 1

static func weapon_mnd_dmg(w: Weapon) -> int:
	var val: int = _get_i(w, "mnd_dmg")
	return val if val > 0 else 1

static func weapon_acc_atk(w: Weapon) -> int:
	var v: int = _get_i(w, "acc_atk")
	if v != 0: return v
	return _get_i(w, "acc")

static func weapon_acc_mnd(w: Weapon) -> int:
	var v: int = _get_i(w, "acc_mnd")
	if v != 0: return v
	return _get_i(w, "acc")

static func weapon_channel(w: Weapon) -> Channel:
	var s: String = _get_s(w, "channel").to_lower()
	if s.begins_with("brawn") or s.begins_with("brw"): return Channel.BRAWN
	if s.begins_with("mind")  or s.begins_with("mnd"): return Channel.MIND
	return Channel.NEUTRAL

static func armor_penalty(armor: Armor) -> int: return _get_i(armor, "penalty")
static func boots_penalty(boots: Boots) -> int: return _get_i(boots, "penalty")

static func armor_eva(armor: Armor) -> int:
	var v: int = _get_i(armor, "eva")
	if v != 0: return v
	return _get_i(armor, "eva_bonus")

static func boots_eva(boots: Boots) -> int:
	var v: int = _get_i(boots, "eva")
	if v != 0: return v
	return _get_i(boots, "eva_bonus")

static func armor_channel_for(obj: Object) -> Channel:
	var s: String = _get_s(obj, "channel").to_lower()
	if s.begins_with("brawn") or s.begins_with("brw"): return Channel.BRAWN
	if s.begins_with("mind")  or s.begins_with("mnd"): return Channel.MIND
	return Channel.NEUTRAL

static func headband_bonus(cd: CharacterData) -> int:
	if cd == null or not cd.has_method("get"): return 0
	var hb_v: Variant = cd.get("hdb")
	if typeof(hb_v) == TYPE_INT or typeof(hb_v) == TYPE_FLOAT: return int(hb_v)
	var head_v: Variant = cd.get("headband")
	if typeof(head_v) == TYPE_OBJECT:
		var head_obj: Object = head_v
		return _get_i(head_obj, "hdb")
	return 0

static func actor_channel(cd: CharacterData) -> Channel:
	var a: int = brw(cd)
	var b: int = mnd(cd)
	if a > b: return Channel.BRAWN
	if b > a: return Channel.MIND
	return Channel.NEUTRAL

static func _rel(actor_ch: Channel, item_ch: Channel) -> int:
	if item_ch == Channel.NEUTRAL or actor_ch == Channel.NEUTRAL: return 0
	return +1 if actor_ch == item_ch else -1

static func atk_raw_damage(cd: CharacterData, w: Weapon) -> int:
	var scale: int = level_quarter(cd.level)
	var base: int = brw(cd) * scale
	var wpn: int = weapon_atk_dmg(w)
	var rel: int = _rel(actor_channel(cd), weapon_channel(w))
	if rel > 0: wpn = int(ceil(float(wpn) * WPN_CHN_ON_DMG_MULT))
	elif rel < 0: wpn = int(ceil(float(wpn) * WPN_CHN_OFF_DMG_MULT))
	return maxi(1, base + wpn)

static func mnd_raw_damage(cd: CharacterData, w: Weapon) -> int:
	var scale: int = level_quarter(cd.level)
	var base: int = mnd(cd) * scale
	var wpn: int = weapon_mnd_dmg(w)
	var rel: int = _rel(actor_channel(cd), weapon_channel(w))
	if rel > 0: wpn = int(ceil(float(wpn) * WPN_CHN_ON_DMG_MULT))
	elif rel < 0: wpn = int(ceil(float(wpn) * WPN_CHN_OFF_DMG_MULT))
	return maxi(1, base + wpn)

static func atk_acc(cd: CharacterData, w: Weapon) -> int:
	var lvl2: int = int(floor(float(cd.level) / 2.0))
	var vtl_q: int = int(floor(float(vtl(cd)) / 4.0))
	var core: int = 20 + lvl2 + (4 * tpo(cd) + vtl_q)
	var acc: int = core + weapon_acc_atk(w)
	var rel: int = _rel(actor_channel(cd), weapon_channel(w))
	if rel > 0: acc += WPN_CHN_ON_ACC_BONUS
	elif rel < 0: acc += WPN_CHN_OFF_ACC_BONUS
	return acc

static func mnd_acc(cd: CharacterData, w: Weapon) -> int:
	var lvl2: int = int(floor(float(cd.level) / 2.0))
	var fcs_q: int = int(floor(float(fcs(cd)) / 4.0))
	var core: int = 20 + lvl2 + (4 * tpo(cd) + fcs_q)
	var acc: int = core + weapon_acc_mnd(w)
	var rel: int = _rel(actor_channel(cd), weapon_channel(w))
	if rel > 0: acc += WPN_CHN_ON_ACC_BONUS
	elif rel < 0: acc += WPN_CHN_OFF_ACC_BONUS
	return acc

static func atk_eva(cd: CharacterData, armor: Armor, boots: Boots) -> int:
	var lvl2: int = int(floor(float(cd.level) / 2.0))
	var vtl_q: int = int(floor(float(vtl(cd)) / 4.0))
	var core: int = 20 + lvl2 + (4 * tpo(cd) + vtl_q)
	var eva: int = core + armor_eva(armor) + boots_eva(boots)
	var rel_a: int = _rel(actor_channel(cd), armor_channel_for(armor))
	var rel_b: int = _rel(actor_channel(cd), armor_channel_for(boots))
	if rel_a > 0: eva += ARM_CHN_ON_EVA_BONUS
	elif rel_a < 0: eva += ARM_CHN_OFF_EVA_BONUS
	if rel_b > 0: eva += ARM_CHN_ON_EVA_BONUS
	elif rel_b < 0: eva += ARM_CHN_OFF_EVA_BONUS
	return eva

static func mnd_eva(cd: CharacterData, armor: Armor, boots: Boots) -> int:
	var lvl2: int = int(floor(float(cd.level) / 2.0))
	var fcs_q: int = int(floor(float(fcs(cd)) / 4.0))
	var core: int = 20 + lvl2 + (4 * tpo(cd) + fcs_q)
	var eva: int = core + armor_eva(armor) + boots_eva(boots)
	var rel_a: int = _rel(actor_channel(cd), armor_channel_for(armor))
	var rel_b: int = _rel(actor_channel(cd), armor_channel_for(boots))
	if rel_a > 0: eva += ARM_CHN_ON_EVA_BONUS
	elif rel_a < 0: eva += ARM_CHN_OFF_EVA_BONUS
	if rel_b > 0: eva += ARM_CHN_ON_EVA_BONUS
	elif rel_b < 0: eva += ARM_CHN_OFF_EVA_BONUS
	return eva

static func hit_chance(att_acc: int, def_eva: int) -> float:
	var ratio: float = float(att_acc) / maxf(1.0, float(def_eva))
	return clamp(BASE_ACC * ratio, HIT_MIN, HIT_MAX)

static func apply_atk_def(dmg_after_rows: int, defender: CharacterData) -> int:
	var denom: float = float(vtl(defender)) / 100.0 + 1.0
	return max(0, int(floor(float(dmg_after_rows) / denom)))

static func apply_mnd_def(dmg_after_rows: int, defender: CharacterData) -> int:
	var denom: float = float(fcs(defender)) / 100.0 + 1.0
	return max(0, int(floor(float(dmg_after_rows) / denom)))

static func max_hp(cd: CharacterData) -> int:
	return vtl(cd) * level_half(cd.level) + 10 + headband_bonus(cd)

static func max_mp(cd: CharacterData) -> int:
	return fcs(cd) * level_half(cd.level) + 10 + headband_bonus(cd)

static func act_roll(cd: CharacterData, armor: Armor, boots: Boots, d20: int) -> int:
	return tpo(cd) - armor_penalty(armor) + boots_penalty(boots) + d20
