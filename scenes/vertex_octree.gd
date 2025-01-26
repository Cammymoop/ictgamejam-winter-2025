extends RefCounted
class_name VertexOctree

var debug_prints: bool = false  # Toggle for debug output

var center: Vector3
var size: Vector3
var max_vertices: int = 8
var vertices: Array[Dictionary] = []  # Array of {position: Vector3, index: int}
var children: Array[VertexOctree]
var is_leaf: bool = true
var level: int = 0

func _init(center_pos: Vector3, size_vec: Vector3, init_level: int = 0):
	center = center_pos
	size = size_vec
	level = init_level

func insert(position: Vector3, vertex_index: int) -> void:
	if not contains_point(position):
		if debug_prints:
			prints("WARNING: Vertex", vertex_index, "at", position, "outside bounds of node at", center)
		return
		
	if is_leaf:
		vertices.append({"position": position, "index": vertex_index})
		if vertices.size() > max_vertices:
			if debug_prints:
				prints("Splitting node at", center, "with", vertices.size(), "vertices")
			split()
		return
	
	var child_index = get_child_index(position)
	if debug_prints:
		prints("Inserting vertex", vertex_index, "at", position, "into child", child_index, "of node at", center)
	children[child_index].insert(position, vertex_index)

func get_vertices_in_radius(position: Vector3, radius: float) -> Dictionary:
	var result := {
		"indices": [],
		"searched_nodes": [],
	}
	_get_vertices_in_radius_impl(position, radius, result)
	return result

func _get_vertices_in_radius_impl(position: Vector3, radius: float, result: Dictionary) -> void:
	result.searched_nodes.append({"center": center, "level": level})
	
	if is_leaf:
		for vertex in vertices:
			var dist = vertex.position.distance_to(position)
			if dist <= radius:
				result.indices.append(vertex.index)
				if debug_prints:
					prints("  Found vertex", vertex.index, "at", vertex.position, "distance:", dist)
		return
	
	# Check all children that might contain points within radius
	for child in children:
		var child_min = child.center - child.size/2
		var child_max = child.center + child.size/2
		
		# Check if sphere overlaps AABB
		# If sphere center + radius is less than min or sphere center - radius is greater than max
		# on any axis, there's no intersection
		var outside = (
			position.x + radius < child_min.x or position.x - radius > child_max.x or
			position.y + radius < child_min.y or position.y - radius > child_max.y or
			position.z + radius < child_min.z or position.z - radius > child_max.z
		)
		
		if debug_prints:
			prints("  Checking child at", child.center, "bounds:", child_min, "to", child_max)
		if not outside:
			if debug_prints:
				prints("    Sphere intersects AABB, searching child")
			child._get_vertices_in_radius_impl(position, radius, result)
		elif debug_prints:
			prints("    Sphere outside AABB bounds")

func contains_point(point: Vector3) -> bool:
	var half_size = size/2
	return (
		abs(point.x - center.x) <= half_size.x &&
		abs(point.y - center.y) <= half_size.y &&
		abs(point.z - center.z) <= half_size.z
	)

func split() -> void:
	is_leaf = false
	children = []
	var half_size = size / 2
	
	# Create 8 children for octree in the correct order
	# Order matches the bit pattern from get_child_index:
	# index = x | (y << 1) | (z << 2)
	var offsets = [
		Vector3(-1, -1, -1), # 0: 000
		Vector3(1, -1, -1),  # 1: 001
		Vector3(-1, 1, -1),  # 2: 010
		Vector3(1, 1, -1),   # 3: 011
		Vector3(-1, -1, 1),  # 4: 100
		Vector3(1, -1, 1),   # 5: 101
		Vector3(-1, 1, 1),   # 6: 110
		Vector3(1, 1, 1),    # 7: 111
	]
	
	for offset in offsets:
		var child_center = center + offset * (half_size / 2)
		children.append(VertexOctree.new(child_center, half_size, level + 1))
	
	# Redistribute vertices to children
	for vertex in vertices:
		var child_index = get_child_index(vertex.position)
		children[child_index].insert(vertex.position, vertex.index)
	
	vertices.clear()

func get_child_index(position: Vector3) -> int:
	# Return index based on which side of center the position is on
	# This creates a 3-bit index where:
	# bit 0 = x side (0 for left, 1 for right)
	# bit 1 = y side (0 for bottom, 1 for top)
	# bit 2 = z side (0 for front, 1 for back)
	var index = 0
	if position.x >= center.x: index |= 1  # x bit
	if position.y >= center.y: index |= 2  # y bit
	if position.z >= center.z: index |= 4  # z bit
	return index

func debug_print(indent: String = "") -> String:
	var result = indent + "Node at level " + str(level) + ":\n"
	indent += "  "
	result += indent + "center: " + str(center) + " size: " + str(size) + "\n"
	
	if is_leaf:
		result += indent + "Vertices: " + str(vertices.map(func(v): return v.index)) + "\n"
	else:
		result += indent + "Children:\n"
		for i in range(len(children)):
			result += children[i].debug_print(indent + "  ")
	
	return result 