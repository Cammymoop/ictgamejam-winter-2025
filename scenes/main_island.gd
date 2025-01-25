extends Node3D

# Vertex painting setup

var handled_meshes: Array[MeshInstance3D]

# key: mesh_index, value: {surface_index: MeshDataTool}
var handled_surfaces: Dictionary = {}

var fade_amt: float = 0.05

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

	for surface_index in handled_surfaces[mesh_index]:
		var mt = handled_surfaces[mesh_index][surface_index]

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
			for vi in mt.vertex_count:
				var color: Color = mt.get_vertex_color(vi)
				if color.a > 0.99:
					continue
				color.a += fade_amt
				mt.set_vertex_color(vi, color)
			mesh_instance.mesh.surface_remove(surface_index)
			mt.commit_to_surface(mesh_instance.mesh, surface_index)
