extends Node

signal mouse_motion(event: InputEventMouseMotion)

func mouse_is_captured() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func toggle_mouse_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_is_captured() else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not mouse_is_captured() and event is InputEventMouseButton:
		toggle_mouse_capture()

	if event is InputEventMouseMotion:
		mouse_motion.emit(event)
