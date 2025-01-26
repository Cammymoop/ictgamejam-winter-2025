extends Node3D

# Vertex painting setup

var handled_meshes: Array[MeshInstance3D]

# key: mesh_index, value: {surface_index: MeshDataTool}
var handled_surfaces: Dictionary = {}

var fade_amt: float = 0.05
var splash_radius_squared: float = 6.0
# sharp ease out to 1
var splash_falloff: float = 2.54

func _ready() -> void:
	load_surfaces($SquooshIsland)

func load_surfaces(mesh_instance: MeshInstance3D) -> void:
	var mesh_index = find_mesh_index(mesh_instance)
	if mesh_index == -1:
		mesh_index = len(handled_meshes)
		handled_meshes.append(mesh_instance)
		handled_surfaces[mesh_index] = {}
	for i in mesh_instance.mesh.get_surface_count():
		var mt = MeshDataTool.new()
		mt.create_from_surface(mesh_instance.mesh, i)
		handled_surfaces[mesh_index][i] = mt


func splash_meshes(meshes: Array[MeshInstance3D], global_pos: Vector3) -> void:
	for mesh in meshes:
		splash_mesh(mesh, global_pos)

func splash_mesh(mesh: MeshInstance3D, global_pos: Vector3) -> void:
	var mesh_index = find_mesh_index(mesh)
	if mesh_index == -1:
		return
	
	var painted_vertices: int = 0
	var last_color: Color = Color.WHITE

	for surface_index in handled_surfaces[mesh_index]:
		var mt: MeshDataTool = handled_surfaces[mesh_index][surface_index]
		for vi in mt.get_vertex_count():
			var brush_strength = spatial_brush(mt.get_vertex(vi), global_pos)
			if brush_strength > 0.0:
				var color: Color = mt.get_vertex_color(vi)
				last_color = color
				var wetness = max(-0.5, color.a - brush_strength)
				color = Color(1.0, 0, color.b + brush_strength, wetness)
				mt.set_vertex_color(vi, color)
				painted_vertices += 1
		mt_commit(mt, mesh, surface_index)
	
	prints("splash_mesh painted", painted_vertices, "vertices", last_color)

func mt_commit(mt: MeshDataTool, mesh: MeshInstance3D, surface_i: int) -> void:
	mesh.mesh.surface_remove(surface_i)
	mt.commit_to_surface(mesh.mesh, surface_i)

func spatial_brush(pos1: Vector3, pos2: Vector3) -> float:
	var distance_squared = pos1.distance_squared_to(pos2)
	if distance_squared > splash_radius_squared:
		return 0.0
	var distance_result = 1 - (distance_squared / splash_radius_squared)
	return ease(distance_result, splash_falloff)
	

func find_mesh_index(mesh: MeshInstance3D) -> int:
	for i in len(handled_meshes):
		if handled_meshes[i] == mesh:
			return i
	return -1

func global_fade() -> void:
	for mesh_index in handled_surfaces:
		var mesh_instance: MeshInstance3D = handled_meshes[mesh_index]
		for surface_index in handled_surfaces[mesh_index]:
			var mt: MeshDataTool = handled_surfaces[mesh_index][surface_index]
			for vi in mt.get_vertex_count():
				var color: Color = mt.get_vertex_color(vi)
				if color.a > 0.99:
					continue
				color.a += fade_amt
				mt.set_vertex_color(vi, color)
			mt_commit(mt, mesh_instance, surface_index)


func _on_dryer_timeout() -> void:
	global_fade()

func get_dryness_sample(mesh_instance: MeshInstance3D, global_pos: Vector3) -> float:
	var mesh_index = find_mesh_index(mesh_instance)
	if mesh_index == -1:
		return 1.0
	
	# yeah I only use one surface anyway
	var mt: MeshDataTool = handled_surfaces[mesh_index][0]
	
