# scripts/rpg/PartyState.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Persistent player-controlled party state (lives across scenes).
#   Autoload this file as: Partystate  (lowercase 's' to avoid name collisions)
#
# RESPONSIBILITIES:
#   - Hold the party roster (CharacterData resources).
#   - Provide helpers to seed, query, add/remove members.
#   - Seed a starter trio if the roster is empty (dev convenience).
#
# DESIGN NOTES:
#   - Core stats are raised by calendar systems; battle level only affects
#     derived combat stats (HP/MP/etc.) via RPGRules.
#   - CharacterData instances live here so XP and levels persist across scenes.
# ------------------------------------------------------------------------------

extends Node
class_name PartyState

# Maximum number of active party members used in battle spawning.
const MAX_PARTY: int = 3

# Persistent roster. Keep CharacterData instances, not copies, so XP persists.
var members: Array[CharacterData] = []

# ------------------------------------------------------------------------------
# Lifecycle / Seeding
# ------------------------------------------------------------------------------

## Ensure the party has a starter trio for development/testing.
## Call from Main on boot, or lazily from BattleScene before spawning allies.
func ensure_seed(rules: RPGRules) -> void:
	if members.size() > 0:
		return
	members.clear()
	members.append(_make_ally("Ally1", 3, 6, 5, 5, 4, 4, rules))
	members.append(_make_ally("Ally2", 3, 5, 5, 6, 4, 4, rules))
	members.append(_make_ally("Ally3", 3, 4, 5, 7, 4, 4, rules))

# ------------------------------------------------------------------------------
# Queries / Mutations
# ------------------------------------------------------------------------------

## Returns up to 'limit' party members (preserves roster order).
func active_members(limit: int = MAX_PARTY) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	var n: int = min(limit, members.size())
	for i in n:
		out.append(members[i])
	return out

## Add a character if not already present (by instance or by name).
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

## Remove a character by name. Returns true if removed.
func remove_member_by_name(member_name: String) -> bool:
	for i in members.size():
		if members[i].name == member_name:
			members.remove_at(i)
			return true
	return false

## Find a member by name or return null.
func find_member(member_name: String) -> CharacterData:
	for m in members:
		if m.name == member_name:
			return m
	return null

## Clear the roster (useful for New Game / debug).
func clear() -> void:
	members.clear()

# ------------------------------------------------------------------------------
# Sample builders (used only by ensure_seed) — strongly typed and documented
# ------------------------------------------------------------------------------

## Build a sample weapon resource.
func _make_weapon(nm: String, dice_expr: String, limit: int, type_id: int) -> Weapon:
	var w: Weapon = Weapon.new()
	w.name = nm
	w.dice = dice_expr           # e.g., "1d6+4"
	w.weapon_limit = limit       # used in accuracy formulas
	w.attack_type = type_id      # RPGRules.AttackType.*
	return w

## Build a sample armor resource.
func _make_armor(nm: String, val: int, lim: int) -> Armor:
	var ar: Armor = Armor.new()
	ar.name = nm
	ar.armor_value = val         # contributes to atk_def
	ar.armor_limit = lim         # reduces dodge/initiative in your rules
	return ar

## Build a sample boots resource.
func _make_boots(nm: String, val: int, lim: int) -> Boots:
	var b: Boots = Boots.new()
	b.name = nm
	b.armor_value = val
	b.armor_limit = lim
	return b

## Build a sample bracelet resource.
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

## Build a starter ally CharacterData resource.
## NOTE: '_rules' kept for future scaling hooks; underscore silences UNUSED_PARAMETER.
func _make_ally(
		nm: String, lvl: int, s: int, st: int, d: int, it: int, ch: int,
		_rules: RPGRules
	) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.name = nm
	c.level = lvl
	c.xp = 0
	c.refresh_xp_to_next()   # initialize xp_to_next via Progression

	# Core stats (calendar will raise these; battle level affects derived stats)
	c.strength = s
	c.sta = st
	c.dex = d
	c.intl = it
	c.cha = ch

	# Basic affinities and equipment
	c.affinities = [RPGRules.AttackType.SLASH]
	c.weapon = _make_weapon("Katana", "1d6+4", 1, RPGRules.AttackType.SLASH)
	c.armor  = _make_armor("Gi", 1, 0)
        c.boots  = _make_boots("Light Boots", 1, 0)
        var br: Bracelet = _make_bracelet(1)
        c.bracelet = br
        c.skills = ["void_blast"]
        return c
