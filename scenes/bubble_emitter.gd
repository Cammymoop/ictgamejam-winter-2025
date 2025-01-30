extends Node3D

@export_node_path var shootee: NodePath
@onready var shootee_node: Node3D = get_node(shootee)
@onready var timer: Timer = $Timer

@export var bubble_scene: PackedScene = preload("res://scenes/a_bubble.tscn")

var autofiring: bool = false
var plr: Node3D

const BIG_SHOT_MAX_CHARGE: float = 0.8
const BIG_SHOT_KICKBACK_FORCE: float = 180.0
var big_shot: bool = false
var big_shot_charge: float = 0.0
var big_shot_charge_concentration: float = 0.5

var face_offset: Vector3 = Vector3(0, 0, -0.3)

var cur_bubble: Node3D

func _ready() -> void:
	if not shootee_node:
		return
	if shootee_node.name == "Player":
		plr = shootee_node
	else:
		plr = shootee_node.find_parent("Player")
	
func retarget() -> void:
	if shootee_node and shootee_node.get_node_or_null("Head/Camera"):
		shootee_node = shootee_node.get_node("Head/Camera")

func _on_timer_timeout() -> void:
	if not autofiring:
		return

	spawn_bubble(false)

func spawn_bubble(is_big_shot: bool) -> void:
	retarget()
	if shootee_node == null:
		return
	cur_bubble = bubble_scene.instantiate()
	add_child(cur_bubble)
	put_bubble_on_face()
	if is_big_shot:
		cur_bubble.big_mode()
	cur_bubble.setup()

	if not is_big_shot:
		shoot_bubble()

func put_bubble_on_face() -> void:
	cur_bubble.global_transform = shootee_node.global_transform.translated_local(face_offset)

func shoot_bubble() -> void:
	if not cur_bubble:
		return
	cur_bubble.start()
	if cur_bubble.is_big_mode:
		var reverse_direction = -cur_bubble.curr_velocity.normalized()
		plr.apply_central_impulse(reverse_direction * BIG_SHOT_KICKBACK_FORCE * big_shot_charge)
	cur_bubble = null

func ac(input_action: String) -> String:
	if not plr:
		return "_" + input_action
	return plr.player_prefix + input_action

func _process(delta: float) -> void:
	if not shootee_node or not plr:
		return
	if Input.is_action_just_pressed(ac("shoot_1")):
		start_autofire()
	if not Input.is_action_pressed(ac("shoot_1")):
		stop_autofire()
	
	if not autofiring:
		if Input.is_action_just_pressed(ac("shoot_2")):
			start_charging()
		if big_shot and Input.is_action_just_released(ac("shoot_2")):
			fire_big_shot()
	
	if big_shot:
		big_shot_charge = min(big_shot_charge + delta, BIG_SHOT_MAX_CHARGE)
		var mapped_charge: float = ease(big_shot_charge, big_shot_charge_concentration)
		put_bubble_on_face()
		# must update scale after setting transform because that scales it
		cur_bubble.big_mode_update_charge(mapped_charge)

func fire_big_shot() -> void:
	big_shot = false
	shoot_bubble()

func start_charging() -> void:
	big_shot = true
	big_shot_charge = 0.0
	spawn_bubble(true)

func start_autofire() -> void:
	autofiring = true
	timer.start()

func stop_autofire() -> void:
	autofiring = false
	timer.stop()
