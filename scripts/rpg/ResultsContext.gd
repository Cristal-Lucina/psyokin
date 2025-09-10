# scripts/rpg/ResultsContext.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Autoload singleton used to pass post-battle results into the Results scene.
#   Keeps things decoupled (BattleScene -> ResultsScreen -> Main).
# HOW:
#   Project Settings -> Autoload -> add this file as "ResultsContext".
# ------------------------------------------------------------------------------

extends Node
class_name ResultsContext

var has_data: bool = false

# Each ally entry: { "name": String, "level_before": int, "level_after": int, "xp_gained": int }
var allies: Array[Dictionary] = []

# Simple lists; you can expand later (e.g., item drops)
var captured: Array[String] = []
var drops: Array[String] = []

# Where to go after pressing Continue
var return_scene_path: String = "res://scenes/Main.tscn"

func set_results(p_allies: Array[Dictionary], p_captured: Array[String], p_drops: Array[String], p_return: String) -> void:
	has_data = true
	allies = p_allies.duplicate()
	captured = p_captured.duplicate()
	drops = p_drops.duplicate()
	return_scene_path = p_return

func clear() -> void:
	has_data = false
	allies.clear()
	captured.clear()
	drops.clear()
	return_scene_path = "res://scenes/Main.tscn"
