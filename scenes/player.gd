extends RigidBody3D

signal drop_ride

const SPLASHABLE_LAYER = 5

var mouse_sensitivity: = 0.002

var joystick_h_sensetivity: = 4
var joystick_v_sensetivity: = 2

const MOVE_SPEED_BASE = 320.0 * 60
const MOVE_SPEED_AIR = 220.0 * 60
const FLY_SPEED = 190.0 * 60

const JUMP_VELOCITY = 230.0

const BOOST_VELOCITY = 100.0 / 12
const FLY_BOOST_VELOCITY = 80.0 / 12

const LOOK_UP_LIMIT = PI * (1.9/4)
const LOOK_DOWN_LIMIT = -PI * (1.8/4)

var mouse_controls_on: = false
var mouse_motion_signal: Signal
var player_prefix: = "p1_"
var player_number: = 1

var dynamic_friction: = true
var friction_factor: = 0.6
var friction_easing: = 3.0

var level_main: Node

const PLAYER_COLORS: = [ "db6db4", "5cae77" ]

const default_prefixes: = [ "kb_", "con1_" ]

@export var grab_mouse: = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera

var was_on_ground: int = 0

const DASH_RESET_TIME: = 3.2
const DASH_ATTACK_TIME: = 0.6
var dash_reset_timer: = 0.0

const STUN_TIME: = 1.0
var stunned: bool = false
var stun_timer: = 0.0

const DASH_DAMP_INSTANTANEOUS: = 0.2

const POINTS_TO_WIN: = 2

const DEATH_PLANE: = -32.0

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_cursor_vis()

	if grab_mouse:
		set_player_number(1)
	else:
		set_player_number(2)
	look_at_center()

	level_main = find_parent("GameScene").get_node("MainIsland")

func is_dash_attack_active() -> bool:
	return dash_reset_timer <= DASH_ATTACK_TIME

func die() -> void:
	var other_player_num: = 1 if player_number == 2 else 2
	Points.in_match_points[other_player_num - 1] += 1
	if Points.in_match_points[other_player_num - 1] >= POINTS_TO_WIN:
		find_parent("GameScene").player_win(other_player_num)
	else:
		get_tree().reload_current_scene()

func set_player_number(number: int) -> void:
	camera.update_layer(number)
	set_collision_layer_value(player_number + 1, false)
	set_collision_layer_value(number + 1, true)
	player_number = number
	player_prefix = Controller.prefixes[player_number - 1]
	if player_prefix == "kb_":
		find_parent("GameScene").enable_player_mouse(self)
		if not mouse_is_captured():
			toggle_mouse_capture()
		
	set_body_color(PLAYER_COLORS[player_number - 1])

	if Points.in_match_points[player_number - 1] > 0:
		get_parent().get_parent().get_node("CanvasLayer").visible = true

func look_at_center() -> void:
	var pos = Vector3.ZERO
	pos.y = global_position.y
	head.look_at(pos, Vector3.UP)

func set_body_color(color: String) -> void:
	var clr: = Color.from_string(color, Color.MAGENTA)
	$Body.get_surface_override_material(0).albedo_color = clr
	$Head/Camera/HeadV.get_surface_override_material(0).albedo_color = clr

func ac(action_name: String) -> String:
	return player_prefix + action_name

func enable_mouse_controls(use_mouse_motion_signal: Signal) -> void:
	if mouse_controls_on:
		mouse_motion_signal.disconnect(mouse_look)
	mouse_motion_signal = use_mouse_motion_signal
	mouse_motion_signal.connect(mouse_look)
	mouse_controls_on = true

func disable_mouse_controls() -> void:
	mouse_motion_signal.disconnect(mouse_look)
	mouse_motion_signal = Signal()
	mouse_controls_on = false

func mouse_is_captured() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func toggle_mouse_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_is_captured() else Input.MOUSE_MODE_CAPTURED
	update_cursor_vis()

func update_cursor_vis() -> void:
	$Cursor.visible = mouse_is_captured()

func _input(event: InputEvent) -> void:
	if not mouse_controls_on:
		return
	
	if event is InputEventMouseButton:
		var e: = event as InputEventMouseButton
		if e.is_pressed():
			if e.button_index == MOUSE_BUTTON_RIGHT:
				toggle_mouse_capture()
	#elif event is InputEventMouseMotion:
		#mouse_look(event)
	
	
func mouse_look(event: InputEventMouseMotion) -> void:
	if not mouse_is_captured():
		return
	
	camera.rotate_x(-event.relative.y * mouse_sensitivity)
	head.rotate_y(-event.relative.x * mouse_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, LOOK_DOWN_LIMIT, LOOK_UP_LIMIT)

func is_on_floor() -> bool:
	return true

func _physics_process(delta: float) -> void:
	# Handle jump.
	var velocity: = linear_velocity

	if not stunned:
		if Input.is_action_just_pressed(ac("jump")) and was_on_ground > 0:
			apply_central_impulse(Vector3(0, JUMP_VELOCITY, 0))

		var input_dir := Input.get_vector(ac("m_left"), ac("m_right"), ac("m_forward"), ac("m_back"))
		var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var move_speed: = MOVE_SPEED_BASE if was_on_ground > 0 else MOVE_SPEED_AIR

		if not is_riding:
			if direction:
				velocity.x = direction.x * move_speed
				velocity.z = direction.z * move_speed
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
				velocity.z = move_toward(velocity.z, 0, move_speed)
		else:
			direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			velocity = direction * move_speed
	
	apply_central_force(velocity * delta)

	dash_reset_timer = max(0.0, dash_reset_timer - delta)
	stun_timer = max(0.0, stun_timer - delta)
	if stun_timer <= 0.0:
		stunned = false

	if global_position.y < DEATH_PLANE:
		die()
	
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	was_on_ground = max(0, was_on_ground - 1)
	if dynamic_friction and not is_riding:
		do_dynamic_friction(state)
	
	if Input.is_action_just_pressed(ac("dash")):
		if not can_dash():
			return
		linear_velocity = linear_velocity * DASH_DAMP_INSTANTANEOUS
		var dir: = Vector3.ZERO
		if was_on_ground > 0:
			dir = -(head.global_transform.basis.rotated(head.global_transform.basis.x, PI * 0.1)).z
			global_position += Vector3.UP * 0.1
		elif is_riding:
			dir = -camera.global_transform.basis.z
		else:
			dir = -head.global_transform.basis.z
		
		var vel_impulse: float = FLY_BOOST_VELOCITY if is_riding else BOOST_VELOCITY
		linear_velocity += dir * vel_impulse
		dash_reset_timer = DASH_RESET_TIME
	
func can_dash() -> bool:
	return dash_reset_timer <= 0.0

func do_dynamic_friction(state: PhysicsDirectBodyState3D) -> void:
	var min_dryness: = 1.0

	var ground_found: bool = false
	for i in state.get_contact_count():
		var collision_body: PhysicsBody3D = state.get_contact_collider_object(i) as PhysicsBody3D
		if collision_body == null or not collision_body.get_collision_layer_value(SPLASHABLE_LAYER):
			continue
		var global_collision_point: = state.get_contact_collider_position(i)
		var mesh_instance: MeshInstance3D = collision_body.get_parent() as MeshInstance3D
		if mesh_instance == null:
			print_debug("no mesh instance parent of splashable collided thing")
			continue
		
		ground_found = true
		var dryness_sample: float = level_main.get_dryness_sample(mesh_instance, global_collision_point)
		min_dryness = min(min_dryness, dryness_sample)
	
	if ground_found:
		was_on_ground = 2

	if min_dryness > 0.98:
		set_my_friction(friction_factor)
		return
	set_my_friction(friction_factor * ease(min_dryness, friction_easing))

func set_my_friction(value: float) -> void:
	physics_material_override.friction = value


func _process(delta: float) -> void:
	joystick_look(delta)

func joystick_look(delta: float) -> void:
	var h_look = Input.get_axis(ac("look_right"), ac("look_left"))
	head.rotate_y(h_look * joystick_h_sensetivity * delta)
	
	var v_look = Input.get_axis(ac("look_down"), ac("look_up"))
	camera.rotate_x(v_look * joystick_v_sensetivity * delta)
	camera.rotation.x = clamp(camera.rotation.x, LOOK_DOWN_LIMIT, LOOK_UP_LIMIT)

func _exit_tree() -> void:
	if mouse_controls_on:
		if mouse_is_captured():
			toggle_mouse_capture()


var is_riding: = false

func start_riding() -> void:
	if is_riding:
		drop_ride.emit()
	is_riding = true
	gravity_scale = 0.0
	linear_damp = 0.1

func stop_riding() -> void:
	is_riding = false
	gravity_scale = 1.0
	linear_damp = 0.0

func _on_body_entered(other_plr: Node3D) -> void:
	if not other_plr.get_collision_layer_value(12):
		return
	
	if not is_dash_attack_active() and other_plr.is_dash_attack_active():
		stunned = true
		var vel: Vector3 = other_plr.linear_velocity

		apply_central_impulse(vel * 100.0)
