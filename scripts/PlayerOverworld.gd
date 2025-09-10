# scripts/PlayerOverworld.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Simple top-down overworld controller for testing random encounters.
# WHY:
#   Lets you move freely in 2D so EncounterManager can measure distance.
# INPUT:
#   move_left, move_right, move_up, move_down (already in your Input Map)
# ------------------------------------------------------------------------------

extends CharacterBody2D
class_name PlayerOverworld

#region Tunables
@export_range(60.0, 600.0, 5.0) var move_speed: float = 220.0
@export_range(0.0, 2000.0, 10.0) var acceleration: float = 1200.0
@export_range(0.0, 2000.0, 10.0) var deceleration: float = 1600.0
#endregion

func _physics_process(delta: float) -> void:
	# Read input and build a normalized 2D intent vector.
	var intent := Vector2(
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down"))  - int(Input.is_action_pressed("move_up"))
	)
	if intent.length() > 0.0:
		intent = intent.normalized()

	# Target velocity is intent scaled by move_speed.
	var target_vel := intent * move_speed

	# Accelerate toward target when moving; decelerate to stop when not.
	var rate := acceleration if target_vel.length() > 0.0 else deceleration
	velocity = velocity.move_toward(target_vel, rate * delta)

	# Move the body; no gravity in top-down.
	move_and_slide()
