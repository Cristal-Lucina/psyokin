# res://scripts/combat/CombatTuning.gd
extends RefCounted
class_name CombatTuning

# --- HIT / CRIT ---------------------------------------------------------------
const BASE_HIT: float      = 0.80      # baseline 80%
const DEX_TO_HIT: float    = 0.02       # +2% per DEX diff
const MIN_HIT: float       = 0.20       # never below 20%
const MAX_HIT: float       = 0.95       # never above 95%

const BASE_CRIT: float     = 0.05
const DEX_TO_CRIT: float   = 0.01
const MIN_CRIT: float      = 0.01
const MAX_CRIT: float      = 0.50

# --- PHYSICAL -----------------------------------------------------------------
const ATK_BASE: float      = 1.0
const STR_TO_ATK: float    = 1.0
const STA_TO_DEF: float    = 0.50

# --- MAGIC --------------------------------------------------------------------
const INT_TO_MATK: float   = 1.6
const MDEF_FROM_STA: float = 0.60

# --- VARIANCE -----------------------------------------------------------------
const DAMAGE_VAR: float    = 0.15       # ±15%

static func hit_chance(att_dex: int, tar_dex: int) -> float:
	var chance: float = BASE_HIT + DEX_TO_HIT * float(att_dex - tar_dex)
	return clamp(chance, MIN_HIT, MAX_HIT)

static func crit_chance(att_dex: int, tar_dex: int) -> float:
	var chance: float = BASE_CRIT + DEX_TO_CRIT * float(att_dex - tar_dex)
	return clamp(chance, MIN_CRIT, MAX_CRIT)

static func physical_base(att_str: int, tgt_sta: int) -> int:
	var base: float = ATK_BASE + STR_TO_ATK * float(att_str)
	var defv: float = STA_TO_DEF * float(tgt_sta)
	var raw: float = max(1.0, base - defv)
	var vmod: float = 1.0 + (randf() * 2.0 - 1.0) * DAMAGE_VAR
	return max(1, int(round(raw * vmod)))

static func magic_base(att_int: int, tgt_sta: int) -> int:
	var base: float = INT_TO_MATK * float(att_int)
	var defv: float = MDEF_FROM_STA * float(tgt_sta)
	var raw: float = max(1.0, base - defv)
	var vmod: float = 1.0 + (randf() * 2.0 - 1.0) * DAMAGE_VAR
	return max(1, int(round(raw * vmod)))
