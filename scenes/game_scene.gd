extends Node3D

@onready var paint_manager: Node = $MainIsland

@export var auto_fix_viewports: = true

func _ready() -> void:
	if auto_fix_viewports:
		fix_viewports()

func enable_player_mouse(player) -> void:
	player.enable_mouse_controls($MouseInputHandler.mouse_motion)

func get_paint_manager() -> Node:
	return paint_manager

func player_win(player_num:int) -> void:
	$Control.visible = true
	for c in $Control/Panel.get_children():
		c.visible = false
	get_node("Control/Panel/Win" + str(player_num)).visible = true
	get_tree().paused = true

	Points.points[player_num - 1] += 1

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fix_viewports"):
		fix_viewports()

	if Input.is_action_just_pressed("reset"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func fix_viewports() -> void:
	var vp: SubViewportContainer = $SubViewportContainer
	vp.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	vp.set_anchor_and_offset(SIDE_LEFT, 0.5, 0)	
	var vp2: SubViewportContainer = $SubViewportContainer2
	vp2.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	vp2.set_anchor_and_offset(SIDE_RIGHT, 0.5, 0)
	get_window().mode = Window.MODE_FULLSCREEN
