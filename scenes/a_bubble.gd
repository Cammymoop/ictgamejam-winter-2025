extends Area3D

@export var disabled: bool = false

@export var base_speed: float = 8.0
@export var base_scale: float = 1.0
@export var color: Color = Color("e05dbb")
@export var upforce: float = 0.2
@export var base_lifetime: float = 12.0

@export_category("Dynamics")
@export var damping_amount: float = 1.0
@export var damping_onset: float = 0.5
@export var damping_reverse_onset: float = 0.7
@export var damping_reverse_endpoint: float = 0.8
@export_exp_easing var damping_concentration: float = 0.5
@export_exp_easing var damping_reverse_concentration: float = 0.5

@export_category("Deviance")
@export var speed_spread: float = 0.2
@onready var speed_deviance: float = up_down_rand(speed_spread)

@export_range(0.0, 0.5) var aim_spread: float = 0.05
@export_exp_easing var aim_spread_concentration: float = 0.5

@export_range(0.0, 1.0) var lifetime_deviance: float = 0.2

@onready var small_area: Area3D = $small

const SPLASHABLE_LAYER: int = 5

var my_speed: float = 0.0
var my_direction: Vector3 = Vector3.FORWARD
var curr_velocity: Vector3 = Vector3.ZERO
var my_lifetime: float = 0.0
var elapsed: float = 0.0

var push_impulse: float = 45.0

func up_down_rand(spread: float) -> float:
	return randf_range(1 - spread, 1 + spread)

func _ready():
	if disabled:
		visible = false
		set_physics_process(false)
	
	$MeshInstance3D.get_surface_override_material(0).albedo_color = color

func start() -> void:
	if disabled:
		return

	my_lifetime = up_down_rand(lifetime_deviance) * base_lifetime
	my_speed = base_speed * speed_deviance
	my_direction = -global_transform.basis.z
	
	if aim_spread > 0.0:
		var rand_angle = randf_range(0.0, 2.0 * PI)
		var spread_axis = Vector3(cos(rand_angle), sin(rand_angle), 0.0)

		var rand_spread = ease(randf(), aim_spread_concentration) * aim_spread
		my_direction = my_direction.rotated(spread_axis, rand_spread)

	curr_velocity = my_speed * my_direction

func _physics_process(delta):
	elapsed += delta / my_lifetime
	if elapsed > 1.0:
		queue_free()

	var damping: = 0.0
	if elapsed > damping_onset and elapsed < damping_reverse_onset:
		var damping_elapsed = elapsed - damping_onset
		damping = ease(damping_elapsed, damping_concentration)
	elif elapsed > damping_reverse_onset and elapsed < damping_reverse_endpoint:
		var damping_elapsed = elapsed - damping_reverse_onset
		damping = ease(1 - damping_elapsed, damping_reverse_concentration)
	damping *= damping_amount * delta

	curr_velocity *= 1.0 - damping
	curr_velocity += Vector3.UP * upforce * delta

	position += curr_velocity * delta

func _process(_delta):
	for body in small_area.get_overlapping_bodies():
		var is_splashable = body.get_collision_layer_value(SPLASHABLE_LAYER)
		if is_splashable:
			detected_splashable(body)
			return

func _on_body_entered(body: CollisionObject3D) -> void:
	print(body.name)
	body.apply_central_impulse(push_impulse * curr_velocity.normalized())

func detected_splashable(body: CollisionObject3D) -> void:
	var paint_manager = get_node("/root/GameScene").get_paint_manager()
	var mesh_instance: MeshInstance3D = body.get_parent() as MeshInstance3D
	if not mesh_instance:
		prints("no MeshInstance3D as splashable parent")
		queue_free()
		return
	paint_manager.splash_mesh(mesh_instance, global_position)
	queue_free()



func _on_area_entered(area:Area3D) -> void:
	if area.get_collision_layer_value(7):
		area.get_parent().got_hit()
