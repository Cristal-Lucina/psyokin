extends Node
class_name BattleLoader

@export var manager_path: NodePath
@export_file("*.tscn") var battle_scene_path: String = "res://scenes/Battle.tscn"

@onready var _manager: EncounterManager = get_node_or_null(manager_path) as EncounterManager
@onready var _ctx: BattleContext = get_node("/root/Battlecontext") as BattleContext  # note lowercase c

func _ready() -> void:
	if _manager == null:
		push_warning("BattleLoader: manager_path not set or node not found.")
		return
	_manager.encounter_started.connect(_on_encounter_started)

func _on_encounter_started(count: int, rows: Array[int], rng_seed: int) -> void:
	if _ctx == null:
		push_error("BattleLoader: Battlecontext autoload missing. Check Project Settings → Autoload.")
		return
	_ctx.set_encounter(count, rows, rng_seed)
	var err := get_tree().change_scene_to_file(battle_scene_path)
	if err != OK:
		push_error("Failed to change to battle scene: %s" % str(err))
