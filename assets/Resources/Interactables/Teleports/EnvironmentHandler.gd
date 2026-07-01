extends Node2D

@export var player_node : Node2D

@export var is_building_insides: bool = false

func swap_to_me():
	teleport_player_to_spawn()
	set_camera_limits()
	await get_tree().create_timer(0.75).timeout
	await Fade.fade_out(0.5)

func teleport_player_to_spawn():
	var spawn_point
	if Global.current_loading_zone == "":
		return
	elif Global.current_loading_zone == "Bedroom":
		spawn_point = find_child(Global.current_loading_zone, true, false).get_child(0)
	else:
		spawn_point = find_child(Global.current_loading_zone, true, false)
	
	if is_building_insides:
		spawn_point = spawn_point.get_child(1)
	else:
		spawn_point = spawn_point.get_child(0)

	if spawn_point:
		if player_node:
			player_node.global_position = spawn_point.global_position

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
