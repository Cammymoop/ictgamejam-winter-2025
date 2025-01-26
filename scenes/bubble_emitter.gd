extends Node3D

@export_node_path var shootee: NodePath
@onready var shootee_node: Node3D = get_node(shootee)
@onready var timer: Timer = $Timer

@export var bubble_scene: PackedScene = preload("res://scenes/a_bubble.tscn")

var autofiring: bool = false
var plr: Node3D

func _ready() -> void:
	if not shootee_node:
		return
	if shootee_node.name == "Player":
		plr = shootee_node
	else:
		plr = shootee_node.find_parent("Player")
	

func _on_timer_timeout() -> void:
	if not autofiring:
		return
	if shootee_node and shootee_node.get_node_or_null("Head/Camera"):
		shootee_node = shootee_node.get_node("Head/Camera")
	if shootee_node == null:
		return

	var bubble: = bubble_scene.instantiate()
	add_child(bubble)
	bubble.global_transform = shootee_node.global_transform
	bubble.scale = Vector3.ONE
	bubble.start()

func _process(_delta: float) -> void:
	if not shootee_node or not plr:
		return
	var input_prefix: String = plr.player_prefix
	if Input.is_action_just_pressed(input_prefix + "shoot_1"):
		start_autofire()
	if not Input.is_action_pressed(input_prefix + "shoot_1"):
		stop_autofire()

func start_autofire() -> void:
	autofiring = true
	timer.start()

func stop_autofire() -> void:
	autofiring = false
	timer.stop()
