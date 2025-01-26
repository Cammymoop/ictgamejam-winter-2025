extends Node3D

@export_node_path var shootee: NodePath
@onready var shootee_node: Node3D = get_node(shootee)


func _on_timer_timeout() -> void:
	if shootee_node and shootee_node.get_node_or_null("Head/Camera"):
		shootee_node = shootee_node.get_node("Head/Camera")
	if shootee_node == null:
		return

	var bubble: = preload("res://scenes/a_bubble.tscn").instantiate()
	add_child(bubble)
	bubble.global_transform = shootee_node.global_transform
	bubble.scale = Vector3.ONE
	bubble.start()