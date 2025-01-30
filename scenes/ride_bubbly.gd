extends Node3D

signal popped

var player_riding: Node
var is_riden: = false
var scale_high: = 1.0
var scale_low: = 0.5
var health: = 1.0

@export var shrink_over_seconds: = 23.0

@export var scale_concentration: = 0.28

func attach(player: Node) -> void:
	player_riding = player
	is_riden = true
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	player_riding.start_riding()
	player_riding.drop_ride.connect(soft_pop)

func _on_area_3d_body_entered(body:Node3D) -> void:
	if is_riden:
		return
	attach(body)

func pop() -> void:
	if player_riding:
		player_riding.stop_riding()
		player_riding.drop_ride.disconnect(soft_pop)
	soft_pop()

func soft_pop() -> void:
	queue_free()
	popped.emit()

func _process(delta: float) -> void:
	scale = Vector3.ONE * ease(health, scale_concentration)
	if health <= 0.0:
		pop()
		return

	if not is_riden:
		return

	health -= delta / shrink_over_seconds
	global_position = player_riding.global_position + (Vector3.DOWN * 0.5)

	var scale_factor: = ease(health, scale_concentration)
	scale = Vector3.ONE * ((scale_high - scale_low) * scale_factor + scale_low)

func got_hit() -> void:
	print("hitbub")
	health -= 0.04

func got_hit_big() -> void:
	health -= 0.2
