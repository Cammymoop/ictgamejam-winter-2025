extends Node3D

# Vertex painting setup

var handled_meshes: Array[MeshInstance3D]

# key: mesh_index, value: {surface_index: MeshDataTool}
var handled_surfaces: Dictionary = {}

var fade_amt: float = 0.05
var splash_radius_squared: float = 6.0
# gradual ease in to 1
var splash_falloff: float = 2.54

# key: mesh_index, value: Dictionary[surface_index, VertexOctree]
var vertex_octrees: Dictionary = {} 

func _ready() -> void:
	load_surfaces($SquooshIsland)
	load_surfaces($SquooshIsland2)
	load_surfaces($SquooshIsland3)

func load_surfaces(mesh_instance: MeshInstance3D, debug_prints: bool = false) -> void:
	var mesh_index = find_mesh_index(mesh_instance)
	if mesh_index == -1:
		mesh_index = len(handled_meshes)
		handled_meshes.append(mesh_instance)
		handled_surfaces[mesh_index] = {}
		vertex_octrees[mesh_index] = {}
	
	for i in mesh_instance.mesh.get_surface_count():
		var mt = MeshDataTool.new()
		mt.create_from_surface(mesh_instance.mesh, i)
		handled_surfaces[mesh_index][i] = mt
		
		# Create and populate octree for this surface
		var bounds = mesh_instance.mesh.get_aabb()
		bounds = bounds.grow(0.1)
		var octree = VertexOctree.new(bounds.position + bounds.size/2, bounds.size)
		
		if debug_prints:
			prints("\nBuilding octree for surface", i)
			prints("Bounds:", bounds)
			prints("Octree center:", octree.center, "size:", octree.size)
		
		var vertex_positions = []
		var vertex_count = 0
		
		for vi in mt.get_vertex_count():
			var vertex_pos = mt.get_vertex(vi)
			vertex_positions.append(vertex_pos)
			if not octree.contains_point(vertex_pos):
				prints("Warning: Vertex", vi, "at", vertex_pos, "outside octree bounds!")
			octree.insert(vertex_pos, vi)
			vertex_count += 1
		
		if debug_prints:
			prints("First few vertex positions:", vertex_positions.slice(0, 5))
			prints("Total vertices:", vertex_count)
			prints("Octree structure:", octree.debug_print())
		
		vertex_octrees[mesh_index][i] = octree

func splash_meshes(meshes: Array[MeshInstance3D], global_pos: Vector3) -> void:
	for mesh in meshes:
		splash_mesh(mesh, global_pos)

func splash_mesh(mesh: MeshInstance3D, global_pos: Vector3, debug_prints: bool = false) -> void:
	var mesh_index = find_mesh_index(mesh)
	if mesh_index == -1:
		return
	
	var painted_vertices: int = 0
	var last_query_result: Dictionary
	var radius = sqrt(splash_radius_squared) + 0.1
	
	# Transform global position to local space for each mesh
	var local_pos = mesh.global_transform.inverse() * global_pos

	for surface_index in handled_surfaces[mesh_index]:
		var mt: MeshDataTool = handled_surfaces[mesh_index][surface_index]
		var octree = vertex_octrees[mesh_index][surface_index]
		
		last_query_result = octree.get_vertices_in_radius(local_pos, radius)
		
		# Debug - check distances to all vertices and show which ones should be found
		var vertices_in_range = []
		for vi in mt.get_vertex_count():
			var vertex_pos = mt.get_vertex(vi)
			var dist = vertex_pos.distance_to(local_pos)
			if dist <= radius:
				vertices_in_range.append({"index": vi, "pos": vertex_pos, "dist": dist})
		
		if debug_prints:
			prints("\nQuery at:", local_pos, "radius:", radius)
			prints("Direct check found", len(vertices_in_range), "vertices:")
			for v in vertices_in_range:
				prints("  Vertex", v.index, "at", v.pos, "distance:", v.dist)
			prints("Octree found", len(last_query_result.indices), "vertices:", last_query_result.indices)
			prints("Searched nodes at levels:", last_query_result.searched_nodes.map(func(n): return n.level))
		
		for vi in last_query_result.indices:
			var vertex_pos = mt.get_vertex(vi)
			var brush_strength = spatial_brush(vertex_pos, local_pos)
			if brush_strength > 0.0:
				var color: Color = mt.get_vertex_color(vi)
				var wetness = max(-0.5, color.a - brush_strength)
				color = Color(1.0, 0, color.b + brush_strength, wetness)
				mt.set_vertex_color(vi, color)
				painted_vertices += 1
		
		mt_commit(mt, mesh, surface_index)
	
	if debug_prints:
		prints("splash_mesh painted", painted_vertices, "vertices at", global_pos, 
			"\n  searched", len(last_query_result.searched_nodes), "nodes at levels:", 
			last_query_result.searched_nodes.map(func(n): return n.level), "\n")

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
	
	# Transform to local space
	var local_pos = mesh_instance.global_transform.inverse() * global_pos
	
	var mt: MeshDataTool = handled_surfaces[mesh_index][0]
	var octree = vertex_octrees[mesh_index][0]
	
	var query_result = octree.get_vertices_in_radius(local_pos, 1.5)
	if query_result.indices.is_empty():
		return 1.0
	
	# Find actual closest vertex
	var closest_dist := INF
	var closest_vertex_index := -1
	
	for vi in query_result.indices:
		var dist = mt.get_vertex(vi).distance_to(local_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_vertex_index = vi
	
	return mt.get_vertex_color(closest_vertex_index).a
