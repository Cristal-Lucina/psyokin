# res://scripts/combat/CombatTuning.gd
# Central place for combat constants (hit, crit, damage curves).
class_name CombatTuning

const BASE_HIT: float = 0.80       # 80% hit chance when DEX is equal
const DEX_TO_HIT: float = 0.03     # Each point of (attDEX - defDEX) shifts hit by 3%
const MIN_HIT: float = 0.05        # Never below 5%
const MAX_HIT: float = 0.97        # Never above 97%

const BASE_CRIT: float = 0.05
const DEX_TO_CRIT: float = 0.005
const CRIT_MULT: float = 1.5

# Physical / magical damage scaling
const ATK_BASE: int = 2
const STR_TO_ATK: float = 1.0
const STA_TO_DEF: float = 0.5
const INT_TO_MATK: float = 1.1
const MDEF_FROM_STA: float = 0.4

# Random variance (± value applied after base calc)
const DAMAGE_VAR: int = 2
