extends Node2D

func _ready():
	teleport_player_to_spawn()
	
func teleport_player_to_spawn():
	if Global.current_loading_zone == "":
		return
	var spawn_point = find_child(Global.current_loading_zone, true, false)
	
	if spawn_point:
		var player = get_tree().get_first_node_in_group("Overworld_Player")
		if player:
			player.global_position = spawn_point.global_position
	else:
		print("No player found")	
