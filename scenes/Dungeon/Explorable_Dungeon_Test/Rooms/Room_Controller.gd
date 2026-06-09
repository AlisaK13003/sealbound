extends Node3D

class_name room

@export var entrance_markers: Dictionary[Node3D, bool]

@export var spawn_points: Array[Marker3D]

@export var grid_size: Vector2


func get_combined_size(parent_node: Node3D) -> Vector3:
	var combined_aabb: AABB
	var has_any_bounds: bool = false
	var parent_inv_transform = parent_node.global_transform.affine_inverse()
	
	# Iterative stack to traverse all nested children without needing helper functions
	var stack = [parent_node]
	while stack.size() > 0:
		var current = stack.pop_back()
		stack.append_array(current.get_children())
		
		# Skip checking bounds on the root parent node itself
		if current == parent_node:
			continue
			
		var local_aabb: AABB
		var has_aabb: bool = false
		
		# Retrieve local bounds from meshes or collision shapes
		if current is VisualInstance3D:
			local_aabb = current.get_aabb()
			has_aabb = true
		elif current is CollisionShape3D and current.shape:
			var debug_mesh = current.shape.get_debug_mesh()
			if debug_mesh:
				local_aabb = debug_mesh.get_aabb()
				has_aabb = true
				
		if has_aabb:
			# Convert bounds into the parent's coordinate space
			var relative_transform = parent_inv_transform * current.global_transform
			var relative_aabb = relative_transform * local_aabb
			
			if not has_any_bounds:
				combined_aabb = relative_aabb
				has_any_bounds = true
			else:
				combined_aabb = combined_aabb.merge(relative_aabb)
				
	return combined_aabb.size if has_any_bounds else Vector3.ZERO
