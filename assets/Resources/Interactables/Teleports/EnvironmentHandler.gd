extends Node2D

@export var player_node : Node2D

@export var is_building_insides: bool = false

func swap_to_me():
	teleport_player_to_spawn()
	set_camera_limits()
	#await get_tree().create_timer(0.75).timeout
	await Fade.fade_out(0.5)

func teleport_player_to_spawn():
	if Global.current_loading_zone == "":
		return
		
	print("Current Loading Zone ", Global.current_loading_zone)
	print("Current Region ", Global.current_region)
	var spawn_point = find_loading_zone_spawn(Global.current_loading_zone)
	if spawn_point == null:
		push_warning("EnvironmentHandler: Could not find loading zone spawn '%s' in %s." % [Global.current_loading_zone, scene_file_path])
		return
	
	#if is_building_insides:
	#	spawn_point = spawn_point
	#else:
	#	spawn_point = spawn_point.get_child(0)
	spawn_point.is_disabled = true
	if player_node:
		player_node.global_position = spawn_point.global_position

func find_loading_zone_spawn(loading_zone_name: String) -> Node2D:
	var named_node = find_child(loading_zone_name, true, false)
	if named_node != null:
		if is_loading_zone_node(named_node):
			return named_node as Node2D
		var child_loading_zone = named_node.find_child("LoadingZone", true, false)
		if child_loading_zone != null and is_loading_zone_node(child_loading_zone):
			return child_loading_zone as Node2D

	return find_loading_zone_by_current_spot(self, loading_zone_name)

func find_loading_zone_by_current_spot(node: Node, loading_zone_name: String) -> Node2D:
	if node != self and is_loading_zone_node(node) and str(node.get("Current Location/Spot")) == loading_zone_name:
		return node as Node2D

	for child in node.get_children():
		var result = find_loading_zone_by_current_spot(child, loading_zone_name)
		if result != null:
			return result

	return null

func is_loading_zone_node(node: Node) -> bool:
	return node.get("is_disabled") != null

func set_camera_limits():
	var camera_bounds: Node
	if is_building_insides:
		if Global.current_loading_zone == "Bedroom":
			camera_bounds = find_child("Tavern", true, false).get_child(0)
		else:
			camera_bounds = find_child(Global.current_loading_zone, true, false).get_child(0)
	else:
		camera_bounds = $"Camera Bounds"

	var upper_left_bounds : Vector2 = camera_bounds.get_child(0).global_position
	var bottom_right_bounds : Vector2 = camera_bounds.get_child(1).global_position
	
	player_node.get_node("Camera2D").limit_left = upper_left_bounds.x
	player_node.get_node("Camera2D").limit_right = bottom_right_bounds.x
	player_node.get_node("Camera2D").limit_top = upper_left_bounds.y
	player_node.get_node("Camera2D").limit_bottom = bottom_right_bounds.y
