# scripts/rpg/BattleHUD.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Minimal HUD that lists allies and enemies with current HP.
# HOW:
#   Add as a child (CanvasLayer or Control). Call bind_actors() from BattleScene.
# ------------------------------------------------------------------------------

extends CanvasLayer
class_name BattleHUD

var _ally_labels: Array[Label] = []
var _enemy_labels: Array[Label] = []

func bind_actors(allies: Array[BattleActor], enemies: Array[BattleActor]) -> void:
	# Build UI once.
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var hbox := HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(hbox)

	var ally_panel := VBoxContainer.new()
	ally_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(ally_panel)

	var enemy_panel := VBoxContainer.new()
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(enemy_panel)

	var ally_title := Label.new()
	ally_title.text = "Allies"
	ally_panel.add_child(ally_title)

	var enemy_title := Label.new()
	enemy_title.text = "Enemies"
	enemy_panel.add_child(enemy_title)

	# Create labels and connect signals
	for a in allies:
		var l := Label.new()
		_ally_labels.append(l)
		ally_panel.add_child(l)
		a.hp_changed.connect(func(actor: BattleActor, new_hp: int):
			l.text = "%s  HP: %d / %d" % [actor.data.name, new_hp, actor.max_hp]
		)
		# initial fill
		l.text = "%s  HP: %d / %d" % [a.data.name, a.current_hp, a.max_hp]

	for e in enemies:
		var l2 := Label.new()
		_enemy_labels.append(l2)
		enemy_panel.add_child(l2)
		e.hp_changed.connect(func(actor: BattleActor, new_hp: int):
			l2.text = "%s  HP: %d / %d" % [actor.data.name, new_hp, actor.max_hp]
			if new_hp <= 0:
				l2.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		)
		l2.text = "%s  HP: %d / %d" % [e.data.name, e.current_hp, e.max_hp]
