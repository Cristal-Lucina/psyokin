extends Node
# Simple input echo to verify the Input Map works.

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):  print("move_left")
	if Input.is_action_just_pressed("move_right"): print("move_right")
	if Input.is_action_just_pressed("move_up"):    print("move_up")
	if Input.is_action_just_pressed("move_down"):  print("move_down")
	if Input.is_action_just_pressed("jump"):       print("jump")
	if Input.is_action_just_pressed("pause"):      print("pause")
