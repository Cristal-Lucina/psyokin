# scripts/rpg/BattleContext.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Singleton used to pass encounter data from overworld to the battle scene.
# USE:
#   Project Settings -> Autoload -> Path: this file, Node Name: BattleContext -> Add.
# ------------------------------------------------------------------------------

extends Node
class_name BattleContext

var pending: bool = false
var count: int = 0
var rows: Array[int] = []
var rng_seed: int = 0

func set_encounter(p_count: int, p_rows: Array[int], p_seed: int) -> void:
	pending = true
	count = p_count
	rows = p_rows.duplicate()
	rng_seed = p_seed

func clear() -> void:
	pending = false
	count = 0
	rows.clear()
	rng_seed = 0
