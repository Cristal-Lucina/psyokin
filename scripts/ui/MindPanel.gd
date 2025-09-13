# res://scripts/ui/MindPanel.gd
# Read-only “Mind” tab panel (fills tab content + padding and aggregates skills).
extends Control
class_name MindPanel

@onready var _party: PartyState = get_node_or_null("/root/Partystate") as PartyState

func _ready() -> void:
	# Make sure the party has a seeded hero + bracelet/sigil
	if _party != null:
		_party.ensure_seed(RPGRules.new())
	_build_ui()

func _build_ui() -> void:
	# Clear on hot-reload
	for c in get_children():
		c.queue_free()

	# Outer padding
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(pad)

	# Column content
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(root)

	var who: CharacterData = _get_protagonist()
	var mind_type := "Omega"  # TODO: data-driven later

	# Header row
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Mind"
	title.add_theme_font_size_override("font_size", 20)
	h.add_child(title)

	var mt := Label.new()
	mt.text = "Type: " + mind_type
	mt.add_theme_font_size_override("font_size", 16)
	mt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(mt)

	root.add_child(h)
	root.add_child(_sep())

	# Bracelet section
	var br_title := Label.new()
	br_title.text = "Bracelet"
	br_title.add_theme_font_size_override("font_size", 16)
	root.add_child(br_title)

	var br_info := Label.new()
	var slot_line := Label.new()

	if who != null and who.bracelet != null:
		var slots := int(who.bracelet.slot_count)
		br_info.text = str(who.bracelet.name) + " (slots: " + str(slots) + ")"
		var eq_count := _sigils_for(who.bracelet).size()
		slot_line.text = "Equipped Sigils: " + str(eq_count)
	else:
		br_info.text = "None"
		slot_line.text = "Equipped Sigils: 0"

	root.add_child(br_info)
	root.add_child(slot_line)

	root.add_child(_sep())

	# Skills section
	var sk_title := Label.new()
	sk_title.text = "Skills"
	sk_title.add_theme_font_size_override("font_size", 16)
	root.add_child(sk_title)

	var sk := Label.new()
	sk.autowrap_mode = TextServer.AUTOWRAP_WORD
	var names := _effective_skill_names(who)
	if names.size() > 0:
		sk.text = ", ".join(names)
	else:
		sk.text = "(none)"
	root.add_child(sk)

func _sigils_for(bracelet: Bracelet) -> Array:
	var arr: Array = []
	if bracelet == null:
		return arr
	if bracelet.has_method("equipped_sigils"):
		var got := bracelet.equipped_sigils()
		if got is Array:
			arr = got
	else:
		var any: Variant = bracelet.get("sigils")
		if typeof(any) == TYPE_ARRAY:
			arr = any
	return arr

func _effective_skill_names(cd: CharacterData) -> Array[String]:
	var out: Array[String] = []
	var seen := {}

	# Base skills from character
	if cd != null and cd.skills is Array:
		for s in cd.skills:
			var t := String(s)
			if not seen.has(t):
				seen[t] = true
				out.append(t)

	# Add unlocks from equipped sigils
	if cd != null and cd.bracelet != null:
		var sigs := _sigils_for(cd.bracelet)
		for sig in sigs:
			if sig == null: 
				continue
			var u: Variant = sig.get("unlock_skill_ids")
			if typeof(u) == TYPE_ARRAY:
				for sid in (u as Array):
					var t2 := String(sid)
					if not seen.has(t2):
						seen[t2] = true
						out.append(t2)

	return out

func _get_protagonist() -> CharacterData:
	if _party != null and _party.members is Array and _party.members.size() > 0:
		var lead := _party.members[0]
		if lead is CharacterData:
			return lead
	return null

func _sep() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.07)
	sep.custom_minimum_size = Vector2(0, 2)
	return sep
