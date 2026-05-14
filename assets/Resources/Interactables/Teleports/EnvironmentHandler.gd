extends Node2D

@export var player_node : Node2D
@onready var camera_bounds : Node2D = $"Camera Bounds"

func _ready():
	teleport_player_to_spawn()
	set_camera_limits()

	
func teleport_player_to_spawn():
	if Global.current_loading_zone == "":
		return
	var spawn_point = find_child(Global.current_loading_zone, true, false)
	
	if spawn_point:
		if player_node:
			player_node.global_position = spawn_point.global_position
			await Fade.fade_out()
			print(player_node.global_position)
			Fade.is_fading = false
	else:
		print("No player found")	

func set_camera_limits():
	var upper_left_bounds : Vector2 = camera_bounds.get_child(0).global_position
	var bottom_right_bounds : Vector2 = camera_bounds.get_child(1).global_position
	
	player_node.get_node("Camera2D").limit_left = upper_left_bounds.x
	player_node.get_node("Camera2D").limit_right = bottom_right_bounds.x
	player_node.get_node("Camera2D").limit_top = upper_left_bounds.y
	player_node.get_node("Camera2D").limit_bottom = bottom_right_bounds.y
