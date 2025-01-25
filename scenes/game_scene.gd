extends Node3D

func enable_player_mouse(player) -> void:
	player.enable_mouse_controls($MouseInputHandler.mouse_motion)

