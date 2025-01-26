extends VBoxContainer

@onready var base: Control = get_parent()

var getting_p1_control: bool = false
var getting_p2_control: bool = false

func _ready() -> void:
	$Button.grab_focus()

	if is_no_points():
		hide_score()
	else:
		$Score.text = "SCORE\n" + str(Points.points[0]) + " - " + str(Points.points[1])
	
	Points.in_match_points = [0, 0]

func hide_score() -> void:
	$Score.visible = false
	$Button3.visible = false

func _on_button_pressed() -> void:
	base.get_node("Loading").visible = true
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

func _on_button2_pressed() -> void:
	base.get_node("A").visible = true
	$Button2.release_focus()
	getting_p1_control = true

func _process(_delta: float) -> void:
	if not getting_p1_control and not getting_p2_control:
		return
	
	var prefixes = ["kb_", "con1_", "con2_", "con3_", "con4_"]
	var prefix = "kb_"
	var pressed: bool = false

	for p in prefixes:
		if Input.is_action_just_pressed(p + "jump"):
			pressed = true
			prefix = p
			break

	if not pressed:
		return
	
	if getting_p1_control:
		Controller.prefixes[0] = prefix
		show_p2_thing()
	elif getting_p2_control:
		Controller.prefixes[1] = prefix
		done_controls()

func show_p2_thing() -> void:
	base.get_node("A").visible = false
	base.get_node("B").visible = true
	getting_p1_control = false
	getting_p2_control = true

func done_controls() -> void:
	base.get_node("A").visible = false
	base.get_node("B").visible = false
	getting_p1_control = false
	getting_p2_control = false
	$Button.grab_focus()

func is_no_points() -> bool:
	return Points.points[0] == 0 and Points.points[1] == 0


func _on_button3_pressed() -> void:
	Points.points = [0, 0]
	hide_score()