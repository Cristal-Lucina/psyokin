# scripts/rpg/Bracelet.gd
# ------------------------------------------------------------------------------
# Holds multiple Sigils and may provide base stat bonuses of its own.
# Must extend Resource so CharacterData can export it safely.
# ------------------------------------------------------------------------------

extends Resource
class_name Bracelet

@export var name: String = "Bracelet"
@export var slot_count: int = 0

# Base stat bonuses from the bracelet itself
@export var bonus_str: int = 0
@export var bonus_sta: int = 0
@export var bonus_dex: int = 0
@export var bonus_int: int = 0
@export var bonus_cha: int = 0

# Store as Resources so the inspector accepts them even if class order changes
@export var sigils: Array[Resource] = []   # expect Sigil instances here

func equipped_sigils() -> Array[Sigil]:
	var out: Array[Sigil] = []
	for s in sigils:
		if s is Sigil:
			out.append(s as Sigil)
	return out
