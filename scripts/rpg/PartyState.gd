extends Node
class_name PartyState

const MAX_PARTY: int = 3
var members: Array[CharacterData] = []

func ensure_seed(rules: RPGRules) -> void:
	if members.size() > 0:
		return
	members.clear()
	members.append(_make_ally("Ally1", 3, 6, 5, 5, 4, 4, rules))
	members.append(_make_ally("Ally2", 3, 5, 5, 6, 4, 4, rules))
	members.append(_make_ally("Ally3", 3, 4, 5, 7, 4, 4, rules))

func active_members(limit: int = MAX_PARTY) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	var n: int = min(limit, members.size())
	for i in n:
		out.append(members[i])
	return out

func add_member(data: CharacterData) -> bool:
	if data == null:
		return false
	if members.has(data):
		return false
	for m in members:
		if m.name == data.name:
			return false
	members.append(data)
	return true

func remove_member_by_name(member_name: String) -> bool:
	for i in members.size():
		if members[i].name == member_name:
			members.remove_at(i)
			return true
	return false

func find_member(member_name: String) -> CharacterData:
	for m in members:
		if m.name == member_name:
			return m
	return null

func clear() -> void:
	members.clear()

func _make_weapon(nm: String, dice_expr: String, limit: int, type_id: int) -> Weapon:
	var w: Weapon = Weapon.new()
	w.name = nm
	w.dice = dice_expr
	w.weapon_limit = limit
	w.attack_type = type_id
	return w

func _make_armor(nm: String, val: int, lim: int) -> Armor:
	var ar: Armor = Armor.new()
	ar.name = nm
	ar.armor_value = val
	ar.armor_limit = lim
	return ar

func _make_boots(nm: String, val: int, lim: int) -> Boots:
	var b: Boots = Boots.new()
	b.name = nm
	b.armor_value = val
	b.armor_limit = lim
	return b

func _make_bracelet(sta_bonus: int) -> Bracelet:
	var br: Bracelet = Bracelet.new()
	br.name = "Bracelet"
	br.slot_count = 1
	br.bonus_sta = sta_bonus

	var void_sigil: Sigil = Sigil.new()
	void_sigil.name = "Void Sigil"
	void_sigil.sigil_type = "void"
	void_sigil.unlock_skill_ids = [StringName("void_blast")]
	br.sigils = [void_sigil]
	return br

func _make_ally(
		nm: String, lvl: int, s: int, st: int, d: int, it: int, ch: int,
		_rules: RPGRules
	) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.name = nm
	c.level = lvl
	c.xp = 0
	c.refresh_xp_to_next()

	c.strength = s
	c.sta = st
	c.dex = d
	c.intl = it
	c.cha = ch

	c.affinities = [RPGRules.AttackType.SLASH]
	c.weapon = _make_weapon("Katana", "1d6+4", 1, RPGRules.AttackType.SLASH)
	c.armor  = _make_armor("Gi", 1, 0)
	c.boots  = _make_boots("Light Boots", 1, 0)

	var br: Bracelet = _make_bracelet(1)
	c.bracelet = br

	# ← StringName array (matches CharacterData.skills type)
	c.skills = [StringName("void_blast")]

	return c
