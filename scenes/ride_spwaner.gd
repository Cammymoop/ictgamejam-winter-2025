extends Node3D

var ride_scn: = preload("res://scenes/ride_bubbly.tscn")

func _ready() -> void:
	await get_tree().process_frame
	spawn_ride()

func _on_timer_timeout() -> void:
	spawn_ride()

func spawn_ride() -> void:
	var ride: = ride_scn.instantiate()
	get_parent().add_child(ride)
	ride.global_position = global_position + (Vector3.UP * 1)
	ride.connect("popped", start_tmr)

func start_tmr() -> void:
	$Timer.start()
