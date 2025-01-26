extends Node3D

signal popped

var player_riding: Node
var is_riden: = false
var scale_fac: = 1.0

var health: = 1.0

@export var shrink_over_seconds: = 20.0

@export var scale_concentration: = 0.1

func attach(player: Node) -> void:
	player_riding = player
	is_riden = true
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	player_riding.start_riding()

func _on_area_3d_body_entered(body:Node3D) -> void:
	if is_riden:
		return
	attach(body)

func pop() -> void:
	if player_riding:
		player_riding.stop_riding()
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

	scale = Vector3.ONE * ease(health, scale_concentration)

func got_hit() -> void:
	print("hitbub")
	health -= 0.04
