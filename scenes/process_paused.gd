extends Node3D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = false
	
	if Input.is_action_just_pressed("reset"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
