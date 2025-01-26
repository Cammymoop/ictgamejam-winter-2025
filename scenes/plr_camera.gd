extends Camera3D

func update_layer(new_layer: int) -> void:
	var all_layers: = ~0
	var just_layer: = 1 << new_layer
	cull_mask = all_layers

	for c in get_children():
		c.layers = just_layer
	set_cull_mask_value(new_layer + 1, false)