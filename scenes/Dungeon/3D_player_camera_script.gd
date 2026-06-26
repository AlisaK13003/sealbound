extends Camera3D

@export var player: Node3D
@onready var raycast: RayCast3D = $RayCast3D

var tracked_walls: Dictionary = {}

var active_walls: Array[StaticBody3D] = []

func _physics_process(_delta: float) -> void:
	return
	if not player:
		return
	
	active_walls.clear()
		
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.clear_exceptions()
	raycast.add_exception(player)
	raycast.force_raycast_update()
	
	while raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if collider is StaticBody3D:
			var tile_root = collider.owner if collider.owner else collider.get_parent()
			
			var is_wall = false
			if tile_root:
				var node_name_ok = tile_root.name.begins_with("Section")
				var file_name_ok = false
				if tile_root.scene_file_path:
					var file_name = tile_root.scene_file_path.get_file()
					file_name_ok = file_name.begins_with("Section")
				
				is_wall = node_name_ok or file_name_ok
			
			if is_wall:
				active_walls.append(collider)
		
		raycast.add_exception(collider)
		raycast.force_raycast_update()
			
	if active_walls.size() != 0:
		for wall in active_walls:
			if wall == null:
				continue
			_fade_wall_out(wall)
		
	for wall in tracked_walls.keys():
		if not is_instance_valid(wall):
			tracked_walls.erase(wall)
			continue
			
		if not wall in active_walls:
			if tracked_walls[wall]["fading_out"]:
				_fade_wall_in(wall)

func _gather_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var root_to_search = node.owner if node.owner else node.get_parent()
	if not root_to_search:
		root_to_search = node
		
	_find_meshes_recursive(root_to_search, meshes)
	return meshes

func _find_meshes_recursive(current_node: Node, list: Array[MeshInstance3D]) -> void:
	if current_node is MeshInstance3D:
		list.append(current_node)
	for child in current_node.get_children():
		_find_meshes_recursive(child, list)

func _fade_wall_out(body: StaticBody3D) -> void:
	if body in tracked_walls:
		if tracked_walls[body]["fading_out"]:
			return
		if tracked_walls[body]["tween"]:
			tracked_walls[body]["tween"].kill()
	else:
		tracked_walls[body] = {
			"meshes": _gather_meshes(body),
			"tween": null,
			"fading_out": true
		}
		
	tracked_walls[body]["fading_out"] = true
	var meshes = tracked_walls[body]["meshes"]
	
	var tween = create_tween().set_parallel(true)
	tracked_walls[body]["tween"] = tween
	
	for mesh in meshes:
		if is_instance_valid(mesh):
			var mat = mesh.get_surface_override_material(0)
			if not mat and mesh.mesh:
				mat = mesh.mesh.surface_get_material(0)
				
			if mat and mat is BaseMaterial3D:
				var override_mat = mesh.get_surface_override_material(0)
				if not override_mat:
					override_mat = mat.duplicate() as BaseMaterial3D
					override_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					override_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					override_mat.cull_mode = BaseMaterial3D.CULL_BACK
					mesh.set_surface_override_material(0, override_mat)
				
				tween.tween_property(override_mat, "albedo_color:a", 0.3, 0.25)

func _fade_wall_in(body: StaticBody3D) -> void:
	if not body in tracked_walls:
		return
		
	tracked_walls[body]["fading_out"] = false
	
	if tracked_walls[body]["tween"]:
		tracked_walls[body]["tween"].kill()
		
	var meshes = tracked_walls[body]["meshes"]
	var tween = create_tween().set_parallel(true)
	tracked_walls[body]["tween"] = tween
	
	for mesh in meshes:
		if is_instance_valid(mesh):
			var mat = mesh.get_surface_override_material(0)
			if mat and mat is BaseMaterial3D:
				tween.tween_property(mat, "albedo_color:a", 1.0, 0.25)
				
	tween.chain().tween_callback(func(): _cleanup_wall(body))

func _cleanup_wall(body: StaticBody3D) -> void:
	if body in tracked_walls:
		var meshes = tracked_walls[body]["meshes"]
		for mesh in meshes:
			if is_instance_valid(mesh):
				mesh.set_surface_override_material(0, null)
		tracked_walls.erase(body)
