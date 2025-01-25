extends Camera3D

func update_layer(new_layer: int) -> void:
	var all_layers: = ~0
	var just_layer: = 1 << new_layer
	cull_mask = all_layers

	$Eye.layers = just_layer
	$Eye2.layers = just_layer
	$Mouth.layers = just_layer
	set_cull_mask_value(new_layer + 1, false)