extends RigidBody3D

const SPLASHABLE_LAYER = 5

var mouse_sensitivity: = 0.002

var joystick_h_sensetivity: = 4
var joystick_v_sensetivity: = 2

const MOVE_SPEED_BASE = 360.0 * 60
const JUMP_VELOCITY = 350.0

const LOOK_UP_LIMIT = PI * (3.0/8)
const LOOK_DOWN_LIMIT = -PI * (1.0/4)

var mouse_controls_on: = false
var mouse_motion_signal: Signal
var player_prefix: = "p1_"
var player_number: = 1

var dynamic_friction: = true
var friction_factor: = 0.4
var friction_easing: = 3.0

var level_main: Node

const PLAYER_COLORS: = [ "db6db4", "5cae77" ]

@export var grab_mouse: = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_cursor_vis()

	if grab_mouse:
		find_parent("GameScene").enable_player_mouse(self)
		set_player_number(1)
	else:
		set_player_number(2)
	look_at_center()

	level_main = find_parent("GameScene").get_node("MainIsland")

func set_player_number(number: int) -> void:
	camera.update_layer(number)
	set_collision_layer_value(player_number + 1, false)
	set_collision_layer_value(number + 1, true)
	player_number = number
	player_prefix = "p" + str(number) + "_"
	set_body_color(PLAYER_COLORS[player_number - 1])

func look_at_center() -> void:
	var pos = Vector3.ZERO
	pos.y = global_position.y
	head.look_at(pos, Vector3.UP)

func set_body_color(color: String) -> void:
	var clr: = Color.from_string(color, Color.MAGENTA)
	$Body.get_surface_override_material(0).albedo_color = clr
	$Head.get_surface_override_material(0).albedo_color = clr

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

func _physics_process(_delta: float) -> void:
	# Handle jump.
	var velocity: = linear_velocity

	if Input.is_action_just_pressed(ac("jump")) and is_on_floor():
		apply_central_impulse(Vector3(0, JUMP_VELOCITY, 0))

	var input_dir := Input.get_vector(ac("m_left"), ac("m_right"), ac("m_forward"), ac("m_back"))
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * MOVE_SPEED_BASE
		velocity.z = direction.z * MOVE_SPEED_BASE
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED_BASE)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED_BASE)
	
	apply_central_force(velocity * _delta)
	
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if dynamic_friction:
		do_dynamic_friction(state)

func do_dynamic_friction(state: PhysicsDirectBodyState3D) -> void:
	var min_dryness: = 1.0
	for i in state.get_contact_count():
		var collision_body: PhysicsBody3D = state.get_contact_collider_object(i) as PhysicsBody3D
		if collision_body == null or not collision_body.get_collision_layer_value(SPLASHABLE_LAYER):
			continue
		var global_collision_point: = state.get_contact_collider_position(i)
		var mesh_instance: MeshInstance3D = collision_body.get_parent() as MeshInstance3D
		if mesh_instance == null:
			print_debug("no mesh instance parent of splashable collided thing")
			continue
		
		var dryness_sample: float = level_main.get_dryness_sample(mesh_instance, global_collision_point)
		min_dryness = min(min_dryness, dryness_sample)
	
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
